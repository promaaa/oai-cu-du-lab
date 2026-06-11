#!/usr/bin/env bash
# 05_generate_quectel_f1_configs.sh - Generate OAI CU/access-DU configs for
# the monolithic-donor Quectel backhaul architecture.
#
# The firecell donor is a monolithic gNB and keeps its own generated/runtime
# config outside this repository. This script only prepares the CU that serves
# the minipc access DU and the minipc access DU config whose F1 path is
# wg-quectel-f1 over the Quectel PDU session.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  # shellcheck source=common.sh
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

log "=== Generating OAI F1 configs for monolithic-donor Quectel backhaul ==="
log "Target: firecell 5GC + firecell CU + monolithic donor gNB + minipc access DU"
log "Access F1: $WG_DU_IP -> $WG_CU_IP over $WG_IF"
log ""

log "--- Verifying production configs ---"
ssh_host "$CU_HOST" "
set -euo pipefail
test -f '$CU_PROD_CONF'
printf '[*] CU production config: %s\n' '$CU_PROD_CONF'
wc -l '$CU_PROD_CONF'
test -f '$FIRECELL_DONOR_PROD_CONF'
printf '[*] Monolithic donor gNB config: %s\n' '$FIRECELL_DONOR_PROD_CONF'
wc -l '$FIRECELL_DONOR_PROD_CONF'
"

ssh_host "$DU_HOST" "
set -euo pipefail
test -f '$DU_PROD_CONF'
printf '[*] DU production config: %s\n' '$DU_PROD_CONF'
wc -l '$DU_PROD_CONF'
"

log "--- Generating firecell CU WireGuard-F1 config ---"
ssh_host "$CU_HOST" "
set -euo pipefail
CONF='$CU_QUECTEL_CONF'
PROD='$CU_PROD_CONF'

if [ ! -f \"\${PROD}.bak-quectel\" ]; then
  sudo -n cp \"\$PROD\" \"\${PROD}.bak-quectel\"
fi
sudo -n cp \"\$PROD\" \"\$CONF\"

sudo -n perl -0pi -e '
  s/(local_s_address\s*=\s*\")[^\"]+(\")/\${1}$WG_CU_IP\${2}/g;
  s/(remote_s_address\s*=\s*\")[^\"]+(\")/\${1}$WG_DU_IP\${2}/g;
  s/(local_n_address\s*=\s*\")[^\"]+(\")/\${1}$WG_CU_IP\${2}/g;
  s/(remote_n_address\s*=\s*\")[^\"]+(\")/\${1}$WG_DU_IP\${2}/g;
  s/(local_n_if_name\s*=\s*\")[^\"]*(\")/\${1}$WG_IF\${2}/g;
' \"\$CONF\"

if ! grep -q 'local_n_if_name' \"\$CONF\"; then
  printf '\nlocal_n_if_name = \"$WG_IF\";\n' | sudo -n tee -a \"\$CONF\" >/dev/null
fi

printf '[*] Generated CU config: %s\n' \"\$CONF\"
grep -En 'local_s_address|remote_s_address|local_n_address|remote_n_address|local_n_if_name|GNB_IPV4_ADDRESS_FOR_NG' \"\$CONF\" | head -80 || true

for required in '$WG_CU_IP' '$WG_DU_IP' '$WG_IF'; do
  if ! grep -Fq \"\$required\" \"\$CONF\"; then
    echo \"[!] Generated CU config is missing required value: \$required\"
    exit 2
  fi
done
"

log "--- Generating minipc access DU WireGuard-F1 config ---"
ssh_host "$DU_HOST" "
set -euo pipefail
CONF='$DU_QUECTEL_CONF'
PROD='$DU_PROD_CONF'

if [ ! -f \"\${PROD}.bak-quectel\" ]; then
  sudo -n cp \"\$PROD\" \"\${PROD}.bak-quectel\"
fi
sudo -n cp \"\$PROD\" \"\$CONF\"

sudo -n perl -0pi -e '
  s/(local_s_address\s*=\s*\")[^\"]+(\")/\${1}$WG_DU_IP\${2}/g;
  s/(remote_s_address\s*=\s*\")[^\"]+(\")/\${1}$WG_CU_IP\${2}/g;
  s/(local_n_address\s*=\s*\")[^\"]+(\")/\${1}$WG_DU_IP\${2}/g;
  s/(remote_n_address\s*=\s*\")[^\"]+(\")/\${1}$WG_CU_IP\${2}/g;
  s/(local_n_if_name\s*=\s*\")[^\"]*(\")/\${1}$WG_IF\${2}/g;
  s/(gNB_ID\s*=\s*)[^;]+;/\${1}$ACCESS_GNB_ID;/g;
  s/(gNB_DU_ID\s*=\s*)[^;]+;/\${1}$ACCESS_DU_ID;/g;
  s/(tracking_area_code\s*=\s*)\d+;/\${1}$ACCESS_TAC;/g;
  s/(physCellId\s*=\s*)\d+;/\${1}$ACCESS_PCI;/g;
  s/(nr_cellid\s*=\s*)\d+;/\${1}$ACCESS_NR_CELL_ID;/g;
  s/(sdr_addrs\s*=\s*\")[^\"]+(\")/\${1}serial=$ACCESS_B210_SERIAL\${2}/g;
  s/(att_tx\s*=\s*)\d+/\${1}$ACCESS_ATT_TX/g;
  s/(att_rx\s*=\s*)\d+/\${1}$ACCESS_ATT_RX/g;
' \"\$CONF\"

if ! grep -q 'local_n_if_name' \"\$CONF\"; then
  printf '\nlocal_n_if_name = \"$WG_IF\";\n' | sudo -n tee -a \"\$CONF\" >/dev/null
fi

printf '[*] Access DU identity: DU_ID=%s gNB_ID=%s cell=%s PCI=%s TAC=%s B210=%s att_tx=%s att_rx=%s\n' '$ACCESS_DU_ID' '$ACCESS_GNB_ID' '$ACCESS_NR_CELL_ID' '$ACCESS_PCI' '$ACCESS_TAC' '$ACCESS_B210_SERIAL' '$ACCESS_ATT_TX' '$ACCESS_ATT_RX'
printf '[*] Generated DU config: %s\n' \"\$CONF\"
grep -En 'gNB_ID|gNB_DU_ID|tracking_area_code|physCellId|nr_cellid|sdr_addrs|att_tx|att_rx|local_s_address|remote_s_address|local_n_address|remote_n_address|local_n_if_name' \"\$CONF\" | head -80 || true

for required in '$ACCESS_DU_ID' '$ACCESS_GNB_ID' '$ACCESS_NR_CELL_ID' '$ACCESS_B210_SERIAL' '$WG_DU_IP' '$WG_CU_IP' '$WG_IF'; do
  if ! grep -Fq \"\$required\" \"\$CONF\"; then
    echo \"[!] Generated access DU config is missing required value: \$required\"
    exit 2
  fi
done
if ! grep -Eq 'physCellId\s*=\s*$ACCESS_PCI;' \"\$CONF\" || ! grep -Eq 'tracking_area_code\s*=\s*$ACCESS_TAC;' \"\$CONF\"; then
  echo '[!] Generated access DU config does not show expected access PCI/TAC.'
  exit 2
fi
"

log ""
log "=== Config generation complete ==="
log "Generated configs:"
log "  CU: $CU_HOST:$CU_QUECTEL_CONF"
log "  minipc access DU: $DU_HOST:$DU_QUECTEL_CONF"
log "Monolithic donor gNB config remains external:"
log "  $CU_HOST:$FIRECELL_DONOR_PROD_CONF"
log ""
log "Next: 05_start_core.sh, start the monolithic donor gNB, establish QMI/WireGuard, then 06_start_cu_quectel.sh and 07_start_du_quectel.sh"
