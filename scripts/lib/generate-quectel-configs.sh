#!/usr/bin/env bash
# Internal config generator used only by ./oai-lab.
#
# The firecell donor is a monolithic gNB and keeps its own generated/runtime
# config outside this repository. This script only prepares the CU that serves
# the selected access DU and its config whose F1 path is
# wg-quectel-f1 over the Quectel PDU session.
set -euo pipefail

if [ "${OAI_TUI_SELECTED_CONFIG:-0}" != "1" ]; then
  echo "[!] This is an internal helper. Use ./oai-lab instead." >&2
  exit 2
fi

CU_HOST="${CU_HOST:?CU_HOST is required}"
DU_HOST="${DU_HOST:?DU_HOST is required}"
CU_PROD_CONF="${CU_PROD_CONF:?CU_PROD_CONF is required}"
DU_PROD_CONF="${DU_PROD_CONF:?DU_PROD_CONF is required}"
CU_QUECTEL_CONF="${CU_QUECTEL_CONF:?CU_QUECTEL_CONF is required}"
DU_QUECTEL_CONF="${DU_QUECTEL_CONF:?DU_QUECTEL_CONF is required}"
FIRECELL_DONOR_PROD_CONF="${FIRECELL_DONOR_PROD_CONF:-/home/serber/monolithic/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-firecell-donor-single-core-51prb.conf}"
WG_CU_IP="${WG_CU_IP:-10.250.0.1}"
WG_DU_IP="${WG_DU_IP:-10.250.0.2}"
WG_IF="${WG_IF:-wg-quectel-f1}"

log() {
  printf '[*] %s\n' "$*"
}

ssh_host() {
  local host="$1"
  shift
  local -a ssh_opts
  # shellcheck disable=SC2206
  ssh_opts=(${LAB_SSH_OPTS:--o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8})
  # Arguments are intentionally expanded on the operator host before SSH.
  # shellcheck disable=SC2029
  ssh "${ssh_opts[@]}" "$host" "$@"
}

# Fixed caged-lab access cell. Keep these aligned with the verified Ethernet
# access-radio baseline so stale local overrides cannot weaken the phone cell.
ACCESS_DU_ID="${ACCESS_DU_ID:-0xe01}"
ACCESS_GNB_ID="${ACCESS_GNB_ID:-0xe00}"
ACCESS_NR_CELL_ID="${ACCESS_NR_CELL_ID:-12345678}"
ACCESS_PCI="${ACCESS_PCI:-0}"
ACCESS_TAC="${ACCESS_TAC:-1}"
ACCESS_B210_SERIAL="${ACCESS_B210_SERIAL:?ACCESS_B210_SERIAL is required}"
if [[ "$ACCESS_B210_SERIAL" == *"="* ]]; then ACCESS_SDR_ADDRS="${ACCESS_SDR_ADDRS:-$ACCESS_B210_SERIAL}"; else ACCESS_SDR_ADDRS="${ACCESS_SDR_ADDRS:-serial=$ACCESS_B210_SERIAL}"; fi
ACCESS_ATT_TX="${ACCESS_ATT_TX:-3}"
ACCESS_ATT_RX="${ACCESS_ATT_RX:-12}"
ACCESS_ARFCN_SSB="${ACCESS_ARFCN_SSB:-641280}"
ACCESS_ARFCN_POINTA="${ACCESS_ARFCN_POINTA:-640008}"

DL_BLER_TARGET_UPPER="${DL_BLER_TARGET_UPPER:-0.35}"
DL_BLER_TARGET_LOWER="${DL_BLER_TARGET_LOWER:-0.25}"
UL_BLER_TARGET_UPPER="${UL_BLER_TARGET_UPPER:-0.35}"
UL_BLER_TARGET_LOWER="${UL_BLER_TARGET_LOWER:-0.15}"
FORCE_MCS="${FORCE_MCS:-0}"
DL_MIN_MCS="${DL_MIN_MCS:-10}"
DL_MAX_MCS="${DL_MAX_MCS:-28}"
UL_MIN_MCS="${UL_MIN_MCS:-10}"
UL_MAX_MCS="${UL_MAX_MCS:-28}"
PUSCH_TARGET_SNR_X10="${PUSCH_TARGET_SNR_X10:-150}"
PUCCH_TARGET_SNR_X10="${PUCCH_TARGET_SNR_X10:-200}"
PUSCH_P0_NOMINAL="${PUSCH_P0_NOMINAL:--90}"
PUCCH_P0_NOMINAL="${PUCCH_P0_NOMINAL:--90}"
PRACH_DTX_THRESHOLD="${PRACH_DTX_THRESHOLD:-120}"
PUCCH0_DTX_THRESHOLD="${PUCCH0_DTX_THRESHOLD:-150}"
MAX_PDSCH_REFERENCE_SIGNAL_POWER="${MAX_PDSCH_REFERENCE_SIGNAL_POWER:--27}"

log "=== Generating OAI F1 configs for monolithic-donor Quectel backhaul ==="
log "Target: firecell 5GC + firecell CU + monolithic donor gNB + selected access DU"
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

log "--- Generating selected access DU WireGuard-F1 config ---"
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
  s/(local_n_portd\s*=\s*)\d+/\${1}2153/g;
  s/(remote_n_portd\s*=\s*)\d+/\${1}2153/g;
  s/(local_n_if_name\s*=\s*\")[^\"]*(\")/\${1}$WG_IF\${2}/g;
  s/(gNB_ID\s*=\s*)[^;]+;/\${1}$ACCESS_GNB_ID;/g;
  s/(gNB_DU_ID\s*=\s*)[^;]+;/\${1}$ACCESS_DU_ID;/g;
  s/(tracking_area_code\s*=\s*)\d+;/\${1}$ACCESS_TAC;/g;
  s/(physCellId\s*=\s*)\d+;/\${1}$ACCESS_PCI;/g;
  s/(nr_cellid\s*=\s*)\d+;/\${1}$ACCESS_NR_CELL_ID;/g;
  s/(sdr_addrs\s*=\s*\")[^\"]+(\")/\${1}$ACCESS_SDR_ADDRS\${2}/g;
  s/(att_tx\s*=\s*)\d+/\${1}$ACCESS_ATT_TX/g;
  s/(att_rx\s*=\s*)\d+/\${1}$ACCESS_ATT_RX/g;
  s/(max_pdschReferenceSignalPower\s*=\s*)-?\d+/\${1}$MAX_PDSCH_REFERENCE_SIGNAL_POWER/g;
  s/(absoluteFrequencySSB\s*=\s*)\d+;/\${1}$ACCESS_ARFCN_SSB;/g;
  s/(dl_absoluteFrequencyPointA\s*=\s*)\d+;/\${1}$ACCESS_ARFCN_POINTA;/g;
  s/(pusch_TargetSNRx10\s*=\s*)\d+/\${1}$PUSCH_TARGET_SNR_X10/g;
  s/(pucch_TargetSNRx10\s*=\s*)\d+/\${1}$PUCCH_TARGET_SNR_X10/g;
  s/(p0_NominalWithGrant\s*=\s*)-?\d+/\${1}$PUSCH_P0_NOMINAL/g;
  s/(p0_nominal\s*=\s*)-?\d+/\${1}$PUCCH_P0_NOMINAL/g;
  s/(prach_dtx_threshold\s*=\s*)\d+/\${1}$PRACH_DTX_THRESHOLD/g;
  s/(pucch0_dtx_threshold\s*=\s*)\d+/\${1}$PUCCH0_DTX_THRESHOLD/g;
  s/^\s*(?:dl_bler_target_upper|dl_bler_target_lower|ul_bler_target_upper|ul_bler_target_lower|dl_min_mcs|dl_max_mcs|ul_min_mcs|ul_max_mcs)\s*=\s*[^;]+;\n//mg;
  s/(pucch_TargetSNRx10\s*=\s*\d+;)/\${1}\n    dl_bler_target_upper        = $DL_BLER_TARGET_UPPER;\n    dl_bler_target_lower        = $DL_BLER_TARGET_LOWER;\n    ul_bler_target_upper        = $UL_BLER_TARGET_UPPER;\n    ul_bler_target_lower        = $UL_BLER_TARGET_LOWER;/;
' \"\$CONF\"

if [ \"$FORCE_MCS\" = \"1\" ]; then
  sudo -n perl -0pi -e 's/(MACRLCs\s*=\s*\(\s*\{\s*num_cc\s*=\s*1;)/\${1}\n    dl_min_mcs = $DL_MIN_MCS;\n    dl_max_mcs = $DL_MAX_MCS;\n    ul_min_mcs = $UL_MIN_MCS;\n    ul_max_mcs = $UL_MAX_MCS;/;' \"\$CONF\"
fi

if ! grep -q 'local_n_if_name' \"\$CONF\"; then
  printf '\nlocal_n_if_name = \"$WG_IF\";\n' | sudo -n tee -a \"\$CONF\" >/dev/null
fi

printf '[*] Access DU identity: DU_ID=%s gNB_ID=%s cell=%s PCI=%s TAC=%s SDR=%s att_tx=%s att_rx=%s SSB=%s PointA=%s\n' '$ACCESS_DU_ID' '$ACCESS_GNB_ID' '$ACCESS_NR_CELL_ID' '$ACCESS_PCI' '$ACCESS_TAC' '$ACCESS_SDR_ADDRS' '$ACCESS_ATT_TX' '$ACCESS_ATT_RX' '$ACCESS_ARFCN_SSB' '$ACCESS_ARFCN_POINTA'
printf '[*] Generated DU config: %s\n' \"\$CONF\"
grep -En 'gNB_ID|gNB_DU_ID|tracking_area_code|physCellId|nr_cellid|sdr_addrs|att_tx|att_rx|local_s_address|remote_s_address|local_n_address|remote_n_address|local_n_if_name|absoluteFrequencySSB|dl_absoluteFrequencyPointA|mcs|bler_target' \"\$CONF\" | head -80 || true


for required in '$ACCESS_DU_ID' '$ACCESS_GNB_ID' '$ACCESS_NR_CELL_ID' '$ACCESS_SDR_ADDRS' '$WG_DU_IP' '$WG_CU_IP' '$WG_IF'; do
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
log "  selected access DU: $DU_HOST:$DU_QUECTEL_CONF"
log "Monolithic donor gNB config remains external:"
log "  $CU_HOST:$FIRECELL_DONOR_PROD_CONF"
log ""
log "The generated configs are ready for the current ./oai-lab launch."
