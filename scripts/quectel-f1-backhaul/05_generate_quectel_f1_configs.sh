#!/usr/bin/env bash
# 05_generate_quectel_f1_configs.sh — Generate OAI CU/DU configs with WireGuard F1 addresses
# This creates copies of the production configs with F1 addresses updated for the Quectel/WireGuard path.
# Generated configs are stored on the target hosts, not committed to Git.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  source "$SCRIPT_DIR/common.sh"
else
  echo "[!] common.sh not found"
  exit 1
fi

if [ -f "$REPO_BASE/conf/local/lab.env" ]; then
  # shellcheck source=conf/local/lab.env
  set +e
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null
  set -e
fi

log "=== Phase 4: Generating OAI F1 Configs for Single-CU Quectel Backhaul ==="
log "Source: Ethernet split configs plus firecell donor radio config"
log "Target: one CU, one local firecell donor DU, one minipc access DU over WireGuard"
log ""

# --- Check that production configs exist ---
log "--- Verifying production configs ---"

ssh_host "$CU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }
if [ ! -f '$CU_PROD_CONF' ]; then
  echo '[!] CU production config not found: $CU_PROD_CONF'
  exit 1
fi
log \"CU production config: $CU_PROD_CONF\"
wc -l '$CU_PROD_CONF'
if [ ! -f '$FIRECELL_DONOR_PROD_CONF' ]; then
  echo '[!] Firecell donor radio config not found: $FIRECELL_DONOR_PROD_CONF'
  exit 1
fi
log \"Firecell donor radio config: $FIRECELL_DONOR_PROD_CONF\"
wc -l '$FIRECELL_DONOR_PROD_CONF'
"

ssh_host "$DU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }
if [ ! -f '$DU_PROD_CONF' ]; then
  echo '[!] DU production config not found: $DU_PROD_CONF'
  exit 1
fi
log \"DU production config: $DU_PROD_CONF\"
wc -l '$DU_PROD_CONF'
"

# --- Generate CU config ---
log "--- Generating CU Quectel/WireGuard config ---"
ssh_host "$CU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }

CONF='$CU_QUECTEL_CONF'
PROD='$CU_PROD_CONF'

# Backup production config if backup doesn't exist
if [ ! -f \"\${PROD}.bak-quectel\" ]; then
  sudo cp \"\$PROD\" \"\${PROD}.bak-quectel\"
  log \"Backed up production config to \${PROD}.bak-quectel\"
fi

# Copy to new config name
sudo cp \"\$PROD\" \"\$CONF\"

# The CU must accept one local donor DU and one minipc access DU.  Bind F1-C/F1-U
# on all local addresses, while each DU selects its own remote CU address.
sudo perl -0pi -e '
  s/(local_s_address\s*=\s*\")[^\"]+(\")/\${1}0.0.0.0\${2}/g;
  s/(remote_s_address\s*=\s*\")[^\"]+(\")/\${1}0.0.0.0\${2}/g;
  s/(local_n_address\s*=\s*\")[^\"]+(\")/\${1}0.0.0.0\${2}/g;
  s/(remote_n_address\s*=\s*\")[^\"]+(\")/\${1}0.0.0.0\${2}/g;
' \"\$CONF\"

# Remove a forced F1-U interface if the Ethernet baseline had one. The CU must
# source local donor traffic locally and minipc traffic from wg-quectel-f1 by route.
sudo perl -0pi -e 's/(local_n_if_name\s*=\s*\")[^\"]+(\")/\${1}\${2}/g' \"\$CONF\"

# Verify changes
log \"F1-C local_s_address: \$(grep local_s_address \"\$CONF\" | head -1)\"
log \"F1-C remote_s_address: \$(grep remote_s_address \"\$CONF\" | head -1)\"
log \"F1-U local_n_address: \$(grep local_n_address \"\$CONF\" | head -1)\"
log \"F1-U remote_n_address: \$(grep remote_n_address \"\$CONF\" | head -1)\"
log \"F1-U local_n_if_name: \$(grep local_n_if_name \"\$CONF\" | head -1 || echo 'not forced')\"
log \"Generated CU config: \$CONF\"
"

# --- Generate firecell donor DU config ---
log "--- Generating firecell donor DU local-F1 config ---"
ssh_host "$CU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }

CONF='$FIRECELL_DONOR_DU_CONF'
PROD='$FIRECELL_DONOR_PROD_CONF'

if [ ! -f \"\${PROD}.bak-split-donor\" ]; then
  sudo cp \"\$PROD\" \"\${PROD}.bak-split-donor\"
  log \"Backed up donor radio config to \${PROD}.bak-split-donor\"
fi

sudo cp \"\$PROD\" \"\$CONF\"
sudo perl -0pi -e '
  s/(Active_gNBs\s*=\s*\(\s*\")[^\"]+(\"\s*\);)/\${1}firecell-donor-du\${2}/g;
  s/(gNB_ID\s*=\s*)[^;]+;/\${1}$DONOR_GNB_ID;/g;
  s/(gNB_DU_ID\s*=\s*)[^;]+;/\${1}$DONOR_DU_ID;/g;
  s/(gNB_name\s*=\s*\")[^\"]+(\")/\${1}firecell-donor-du\${2}/g;
  s/(tracking_area_code\s*=\s*)\d+;/\${1}$DONOR_TAC;/g;
  s/(physCellId\s*=\s*)\d+;/\${1}$DONOR_PCI;/g;
  s/(nr_cellid\s*=\s*)\d+;/\${1}$DONOR_NR_CELL_ID;/g;
  s/(tr_s_preference\s*=\s*\")[^\"]+(\")/\${1}local_L1\${2}/g;
  s/(tr_n_preference\s*=\s*\")[^\"]+(\")/\${1}f1\${2}/g;
' \"\$CONF\"

sudo perl -0pi -e '
  s/(L1s\s*=\s*\(\s*\{.*?tr_n_preference\s*=\s*\")[^\"]+(\")/\${1}local_mac\${2}/s;
' \"\$CONF\"

# DU-side F1 endpoint parameters are read from MACRLCs in this OAI tree.
sudo perl -0pi -e '
  s/\n\s*local_[sn]_address\s*=\s*\"[^\"]+\"\s*;?//g;
  s/\n\s*remote_[sn]_address\s*=\s*\"[^\"]+\"\s*;?//g;
  s/\n\s*local_n_if_name\s*=\s*\"[^\"]+\"\s*;?//g;
' \"\$CONF\"
sudo perl -0pi -e '
  s/(MACRLCs\s*=\s*\(\s*\{.*?tr_n_preference\s*=\s*\"f1\"\s*;?)/\${1}\n    local_n_address  = \"$LOCAL_DONOR_F1_DU_IP\";\n    remote_n_address = \"$LOCAL_DONOR_F1_CU_IP\";\n    local_n_if_name  = \"lo\";/s;
' \"\$CONF\"

# DU configs must not keep monolithic/core-side N2/N3 sections.
sudo perl -0pi -e '
  s/\n\s*amf_ip_address\s*=\s*\(\{.*?\}\);\s*//s;
  s/\n\s*\/\/\/+ AMF parameters:\s*NETWORK_INTERFACES\s*:\s*\{.*?\};\s*//s;
  s/\n\s*NETWORK_INTERFACES\s*:\s*\{.*?\};\s*//s;
  s/\n\s*security\s*=\s*\{.*?\};\s*//s;
' \"\$CONF\"

if ! grep -q 'gNB_DU_ID' \"\$CONF\"; then
  sudo perl -0pi -e 's/(gNB_ID\s*=\s*[^;]+;)/\${1}\n    gNB_DU_ID = $DONOR_DU_ID;/' \"\$CONF\"
fi

log \"Donor DU identity: DU_ID=$DONOR_DU_ID gNB_ID=$DONOR_GNB_ID cell=$DONOR_NR_CELL_ID PCI=$DONOR_PCI TAC=$DONOR_TAC\"
grep -En 'gNB_ID|gNB_DU_ID|gNB_name|tracking_area_code|physCellId|nr_cellid|local_n_address|remote_n_address|local_n_if_name|tr_[sn]_preference' \"\$CONF\" | head -50 || true
for required in '$DONOR_DU_ID' '$DONOR_GNB_ID' '$DONOR_NR_CELL_ID' '$LOCAL_DONOR_F1_DU_IP' '$LOCAL_DONOR_F1_CU_IP'; do
  if ! grep -Fq \"\$required\" \"\$CONF\"; then
    echo \"[!] Generated donor DU config is missing required value: \$required\"
    echo '[!] Refusing to continue because donor/access identity separation would be ambiguous.'
    exit 2
  fi
done
if ! grep -Eq 'physCellId\s*=\s*$DONOR_PCI;' \"\$CONF\" || ! grep -Eq 'tracking_area_code\s*=\s*$DONOR_TAC;' \"\$CONF\"; then
  echo '[!] Generated donor DU config does not show expected donor PCI/TAC.'
  exit 2
fi
log \"Generated donor DU config: \$CONF\"
"

# --- Generate DU config ---
log "--- Generating DU Quectel/WireGuard config ---"
ssh_host "$DU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }

CONF='$DU_QUECTEL_CONF'
PROD='$DU_PROD_CONF'
WG_IF='$WG_IF'

# Backup production config if backup doesn't exist
if [ ! -f \"\${PROD}.bak-quectel\" ]; then
  sudo cp \"\$PROD\" \"\${PROD}.bak-quectel\"
  log \"Backed up production config to \${PROD}.bak-quectel\"
fi

# Copy to new config name
sudo cp \"\$PROD\" \"\$CONF\"

# Update F1-C (SCTP) addresses
sudo sed -i \
  's/local_s_address\s*=\s*\"[^\"]*\"/local_s_address               = \"'"$WG_DU_IP"'\"/' \
  \"\$CONF\"
sudo sed -i \
  's/remote_s_address\s*=\s*\"[^\"]*\"/remote_s_address              = \"'"$WG_CU_IP"'\"/' \
  \"\$CONF\"

# Update F1-U (GTP-U) addresses
sudo sed -i \
  's/local_n_address\s*=\s*\"[^\"]*\"/local_n_address               = \"'"$WG_DU_IP"'\"/' \
  \"\$CONF\"
sudo sed -i \
  's/remote_n_address\s*=\s*\"[^\"]*\"/remote_n_address              = \"'"$WG_CU_IP"'\"/' \
  \"\$CONF\"

# Add WireGuard interface binding
if ! grep -q 'local_n_if_name' \"\$CONF\"; then
  echo 'local_n_if_name              = \"'"$WG_IF"'\";' | sudo tee -a \"\$CONF\" >/dev/null
else
  sudo perl -0pi -e 's/(local_n_if_name\s*=\s*\")[^\"]+(\")/\${1}'"$WG_IF"'\${2}/g' \"\$CONF\"
fi

sudo perl -0pi -e '
  s/(gNB_ID\s*=\s*)[^;]+;/\${1}$ACCESS_GNB_ID;/g;
  s/(gNB_DU_ID\s*=\s*)[^;]+;/\${1}$ACCESS_DU_ID;/g;
  s/(tracking_area_code\s*=\s*)\d+;/\${1}$ACCESS_TAC;/g;
  s/(physCellId\s*=\s*)\d+;/\${1}$ACCESS_PCI;/g;
  s/(nr_cellid\s*=\s*)\d+;/\${1}$ACCESS_NR_CELL_ID;/g;
  s/(sdr_addrs\s*=\s*\")[^\"]+(\")/\${1}serial=$ACCESS_B210_SERIAL\${2}/g;
' \"\$CONF\"

# Verify changes
log \"Access DU identity: DU_ID=$ACCESS_DU_ID gNB_ID=$ACCESS_GNB_ID cell=$ACCESS_NR_CELL_ID PCI=$ACCESS_PCI TAC=$ACCESS_TAC B210=$ACCESS_B210_SERIAL\"
log \"F1-C local_s_address: \$(grep local_s_address \"\$CONF\" | head -1)\"
log \"F1-C remote_s_address: \$(grep remote_s_address \"\$CONF\" | head -1)\"
log \"F1-U local_n_address: \$(grep local_n_address \"\$CONF\" | head -1)\"
log \"F1-U remote_n_address: \$(grep remote_n_address \"\$CONF\" | head -1)\"
log \"WireGuard interface: \$(grep local_n_if_name \"\$CONF\" | head -1 || echo 'not found')\"
for required in '$ACCESS_DU_ID' '$ACCESS_GNB_ID' '$ACCESS_NR_CELL_ID' '$ACCESS_B210_SERIAL' '$WG_DU_IP' '$WG_CU_IP' '$WG_IF'; do
  if ! grep -Fq \"\$required\" \"\$CONF\"; then
    echo \"[!] Generated access DU config is missing required value: \$required\"
    echo '[!] Refusing to continue because donor/access identity or F1 path separation would be ambiguous.'
    exit 2
  fi
done
if ! grep -Eq 'physCellId\s*=\s*$ACCESS_PCI;' \"\$CONF\" || ! grep -Eq 'tracking_area_code\s*=\s*$ACCESS_TAC;' \"\$CONF\"; then
  echo '[!] Generated access DU config does not show expected access PCI/TAC.'
  exit 2
fi
log \"Generated DU config: \$CONF\"
"

log ""
log "=== Config generation complete ==="
log "Generated configs:"
log "  CU: $CU_HOST:$CU_QUECTEL_CONF"
log "  firecell donor DU: $CU_HOST:$FIRECELL_DONOR_DU_CONF"
log "  minipc access DU: $DU_HOST:$DU_QUECTEL_CONF"
log ""
log "Next: 05_start_core.sh, 06_start_cu_quectel.sh, 06_start_firecell_donor_du_quectel.sh, then 07_start_du_quectel.sh"
