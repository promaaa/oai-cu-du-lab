#!/usr/bin/env bash
# 08_validate_f1.sh — Validate F1-C and F1-U over Quectel/WireGuard backhaul
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
CU_LOG="${CU_QUECTEL_LOG:-$CU_LOG}"
DU_LOG="${DU_QUECTEL_LOG:-$DU_LOG}"

log "=== Phase 6: Single-CU Quectel F1 Validation ==="
log "Checking local donor DU F1 plus minipc access DU F1 over Quectel/WireGuard"
log ""

# --- Check F1-C (SCTP) ---
log "--- F1-C SCTP Check ---"
log "CU log: checking for F1SetupRequest and F1SetupResponse..."
ssh_host "$CU_HOST" "
set -euo pipefail
if [ -f '$CU_LOG' ]; then
  grep -E '(F1Setup|F1AP|SetupRequest|SetupResponse|association|SCTP)' '$CU_LOG' | tail -n 20 || echo 'No F1-related entries found in CU log'
else
  echo 'CU log file not found: $CU_LOG'
fi
"

log "DU log: checking for F1SetupRequest sent..."
ssh_host "$DU_HOST" "
set -euo pipefail
if [ -f '$DU_LOG' ]; then
  grep -E '(F1Setup|F1AP|SetupRequest|SetupResponse|waiting for F1)' '$DU_LOG' | tail -n 20 || echo 'No F1-related entries found in DU log'
else
  echo 'DU log file not found: $DU_LOG'
fi
"

log "Firecell donor DU log: checking for local F1 setup..."
ssh_host "$CU_HOST" "
set -euo pipefail
if [ -f '$FIRECELL_DONOR_DU_LOG' ]; then
  grep -E '(F1Setup|F1AP|SetupRequest|SetupResponse|waiting for F1|SCTP)' '$FIRECELL_DONOR_DU_LOG' | tail -n 20 || echo 'No donor F1-related entries found'
else
  echo 'Donor DU log file not found: $FIRECELL_DONOR_DU_LOG'
fi
"

# --- Check SCTP port bindings ---
log "--- SCTP Port 2153 Status ---"
ssh_host "$DU_HOST" "
set -euo pipefail
log 'DU SCTP listeners:'
ss -tlnp | grep 2153 || echo 'No SCTP listener on 2153 at DU'
log 'DU SCTP connections:'
ss -tnp | grep 2153 || echo 'No SCTP connection on 2153 at DU'
"

ssh_host "$CU_HOST" "
set -euo pipefail
log 'CU SCTP listeners:'
ss -tlnp | grep 2153 || echo 'No SCTP listener on 2153 at CU'
log 'CU SCTP connections:'
ss -tnp | grep 2153 || echo 'No SCTP connection on 2153 at CU'
"

# --- Check F1-U GTP-U ---
log "--- F1-U GTP-U Check ---"
log "DU log: checking for GTP-U / F1-U / N3 / user-plane entries..."
ssh_host "$DU_HOST" "
set -euo pipefail
if [ -f '$DU_LOG' ]; then
  grep -E '(GTP-U|GTPU|F1-U|user_plane|N3|GNB_DU_PROG|DRB|DRB establishment)' '$DU_LOG' | tail -n 20 || echo 'No F1-U/GTP-U entries found'
else
  echo 'DU log file not found'
fi
"

# --- Packet capture proof (hard PASS gate) ---
log "--- Packet Path Verification ---"
log "PASS requires tcpdump proof for local donor F1, access F1-C/F1-U on $WG_IF, WireGuard outer UDP on $QUECTEL_IFACE, and no minipc F1 on management."
log "For F1-U, start traffic from the Nothing Phone when prompted."

packet_summary="$(mktemp)"
cleanup() {
  rm -f "$packet_summary"
}
trap cleanup EXIT

capture_result() {
  local label="$1"
  local host="$2"
  local iface="$3"
  local filter="$4"
  local seconds="$5"
  local count="$6"
  local cmd
  cmd=$(cat <<EOF
set -euo pipefail
if ! ip link show '$iface' >/dev/null 2>&1; then
  echo '__CAPTURE_STATUS__ missing-iface'
  exit 0
fi
out="\$(timeout '$seconds' sudo -n tcpdump -l -nni '$iface' -c '$count' '$filter' 2>/dev/null || true)"
printf '%s\n' "\$out"
if printf '%s\n' "\$out" | grep -Eiq '(^[0-9:.]+ IP| SCTP | UDP | > )'; then
  echo '__CAPTURE_STATUS__ packets'
else
  echo '__CAPTURE_STATUS__ none'
fi
EOF
)
  log "Capture: $label ($host $iface, filter: $filter)"
  ssh_host "$host" "$cmd" | tee -a "$packet_summary"
}

capture_has_packets() {
  local marker="$1"
  awk -v marker="$marker" '
    $0 == marker { in_block=1; next }
    /^__END__/ { in_block=0 }
    in_block && /__CAPTURE_STATUS__ packets/ { found=1 }
    END { exit found ? 0 : 1 }
  ' "$packet_summary"
}

capture_has_no_packets() {
  local marker="$1"
  awk -v marker="$marker" '
    $0 == marker { in_block=1; next }
    /^__END__/ { in_block=0 }
    in_block && /__CAPTURE_STATUS__ packets/ { found=1 }
    END { exit found ? 1 : 0 }
  ' "$packet_summary"
}

record_capture() {
  local marker="$1"
  shift
  printf '%s\n' "$marker" >>"$packet_summary"
  capture_result "$@"
  printf '__END__ %s\n' "$marker" >>"$packet_summary"
}

record_capture "__DONOR_LOCAL_F1__" "firecell donor local F1" "$CU_HOST" lo "sctp or udp port 2153" 30 40
record_capture "__ACCESS_F1C_WG__" "minipc access F1-C on WireGuard" "$DU_HOST" "$WG_IF" "sctp" 45 40
record_capture "__WG_OUTER_UDP__" "WireGuard outer UDP on Quectel" "$DU_HOST" "$QUECTEL_IFACE" "udp port $WG_PORT or udp port 40016" 30 30

read -r -p "[?] Start Nothing Phone traffic now, then press Enter for F1-U UDP/2153 capture..." _
record_capture "__ACCESS_F1U_WG__" "minipc access F1-U on WireGuard during phone traffic" "$DU_HOST" "$WG_IF" "udp port 2153" 90 60

phone_access_ok=0
read -r -p "[?] Confirm Nothing Phone is inside the cage and attached to the minipc access cell PCI=$ACCESS_PCI/TAC=$ACCESS_TAC. Type YES to include this in PASS: " phone_confirm
if [ "$phone_confirm" = "YES" ]; then
  phone_access_ok=1
fi

mgmt_markers=()
for iface in enp2s0 enp4s0 wlp3s0 wlan0; do
  marker="__MINIPC_MGMT_${iface}__"
  mgmt_markers+=("$marker")
  record_capture "$marker" "minipc management no-F1 check" "$DU_HOST" "$iface" "sctp or udp port 2153" 12 5
done

for iface in enp6s0 enp4s0 wlp3s0 wlan0; do
  marker="__FIRECELL_MGMT_${iface}__"
  mgmt_markers+=("$marker")
  record_capture "$marker" "firecell management no-minipc-F1 check" "$CU_HOST" "$iface" "host $WG_DU_IP and (sctp or udp port 2153)" 12 5
done

donor_local_ok=0
access_f1c_ok=0
access_f1u_ok=0
outer_udp_ok=0
mgmt_clean_ok=1

capture_has_packets "__DONOR_LOCAL_F1__" && donor_local_ok=1
capture_has_packets "__ACCESS_F1C_WG__" && access_f1c_ok=1
capture_has_packets "__ACCESS_F1U_WG__" && access_f1u_ok=1
capture_has_packets "__WG_OUTER_UDP__" && outer_udp_ok=1
for marker in "${mgmt_markers[@]}"; do
  if ! capture_has_no_packets "$marker"; then
    mgmt_clean_ok=0
  fi
done

pass_fail() {
  if [ "$1" = 1 ]; then
    printf PASS
  else
    printf FAIL
  fi
}

log ''
log "=== Packet Gate Summary ==="
log "firecell donor DU local F1 on lo: $(pass_fail "$donor_local_ok")"
log "minipc access DU F1-C SCTP on $WG_IF: $(pass_fail "$access_f1c_ok")"
log "minipc access DU F1-U UDP/2153 on $WG_IF during phone traffic: $(pass_fail "$access_f1u_ok")"
log "WireGuard outer UDP on $QUECTEL_IFACE: $(pass_fail "$outer_udp_ok")"
log "Ethernet/WiFi management interfaces carry no minipc F1: $(pass_fail "$mgmt_clean_ok")"
log "Nothing Phone served by minipc access cell PCI=$ACCESS_PCI/TAC=$ACCESS_TAC: $(pass_fail "$phone_access_ok")"
log ""

if [ "$donor_local_ok" != 1 ] || [ "$access_f1c_ok" != 1 ] || [ "$access_f1u_ok" != 1 ] || [ "$outer_udp_ok" != 1 ] || [ "$mgmt_clean_ok" != 1 ] || [ "$phone_access_ok" != 1 ]; then
  warn "Packet gate FAILED. No PASS claimed."
  warn "Fix the failed item above, then rerun this script. Rollback: ./09_rollback_to_ethernet.sh"
  exit 2
fi

log "=== F1 Validation PASS ==="
log "Validated: donor local F1, access F1-C/F1-U on $WG_IF, WireGuard outer UDP on $QUECTEL_IFACE, no management F1 leakage, and caged phone served by minipc access cell."
log ""
log "If F1-C fails:"
log "  - Check WireGuard tunnel is up (sudo wg show)"
log "  - Check CU is listening on $WG_CU_IP:2153"
log "  - Check DU log for 'waiting for F1 Setup Response'"
log ""
log "Rollback at any time: ./09_rollback_to_ethernet.sh"
