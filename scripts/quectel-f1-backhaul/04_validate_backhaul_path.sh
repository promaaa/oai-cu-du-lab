#!/usr/bin/env bash
# 04_validate_backhaul_path.sh — Verify WireGuard tunnel is up and F1 endpoint is reachable
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
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null || true
fi

log "=== Phase 3: Backhaul Path Validation ==="
log "Validating WireGuard tunnel and connectivity between hosts"
log ""

# Detect Quectel interface if needed
if [ -z "${QUECTEL_IFACE:-}" ]; then
  QUECTEL_IFACE="$(ssh_host "$DU_HOST" "bash -lc '$detect_quectel_iface_cmd'" 2>/dev/null | head -1 || true)"
fi

if [ "$BACKHAUL_MODE" = "wireguard" ]; then
  log "Mode: WireGuard overlay over Quectel"
  log "Tunnel: $WG_DU_IP <-> $WG_CU_IP"
  log ""

  log "--- WireGuard status on DU (serber-minipc) ---"
  ssh_host "$DU_HOST" "
    set -euo pipefail
    sudo wg show '$WG_IF' 2>/dev/null || warn 'WireGuard interface $WG_IF not found on DU'
    ip -br addr show '$WG_IF' 2>/dev/null || true
    ip route get '$WG_CU_IP' 2>/dev/null || true
  "

  log "--- WireGuard status on CU (serber-firecell) ---"
  ssh_host "$CU_HOST" "
    set -euo pipefail
    sudo wg show '$WG_IF' 2>/dev/null || warn 'WireGuard interface $WG_IF not found on CU'
    ip -br addr show '$WG_IF' 2>/dev/null || true
  "

  log "--- Connectivity: DU -> CU tunnel IP ---"
  ssh_host "$DU_HOST" "ping -c 5 '$WG_CU_IP' 2>&1" || warn "Ping to $WG_CU_IP failed"

  log "--- Connectivity: CU -> DU tunnel IP ---"
  ssh_host "$CU_HOST" "ping -c 5 '$WG_DU_IP' 2>&1" || warn "Ping to $WG_DU_IP failed"

  log "--- SCTP/F1 port reachability from DU to CU ---"
  ssh_host "$DU_HOST" "
    set -euo pipefail
    # Check if port is open on CU
    timeout 5 nc -nz '$WG_CU_IP' '$F1_PORT' 2>/dev/null && log 'F1 port $F1_PORT: reachable on $WG_CU_IP' || warn 'F1 port $F1_PORT: NOT reachable'
  "

  log "--- Route verification ---"
  ssh_host "$DU_HOST" "
    set -euo pipefail
    log 'Route to CU management IP:'
    ip route get '$CU_MGMT_IP' || true
    log 'Route to WireGuard CU IP:'
    ip route get '$WG_CU_IP' || true
    log 'Route to WireGuard endpoint:'
    ip route get '${FIRECELL_WG_ENDPOINT_IP}' || true
  "

else
  log "Mode: Direct Quectel IP (no overlay tunnel)"
  log "Direct IP backhaul: $DIRECT_DU_IP -> $DIRECT_CU_IP"
  log ""

  ssh_host "$DU_HOST" "
    set -euo pipefail
    log '--- Direct path tests ---'
    ping -I '$QUECTEL_IFACE' -c 4 '$DIRECT_CU_IP' 2>/dev/null && log 'Direct path to CU: OK' || warn 'Direct path to CU: FAIL'
    timeout 5 nc -nz -s \"\$(ip -4 -o addr show dev '$QUECTEL_IFACE' | awk '{print \$4}' | cut -d/ -f1)\" '$DIRECT_CU_IP' '$F1_PORT' 2>/dev/null && log 'F1 port reachable' || warn 'F1 port not reachable'
  "
fi

log ''
log "=== Backhaul validation complete ==="
log "If all checks pass, proceed to Phase 4: F1 Transport Migration Plan."
log "If WireGuard tunnel or reachability fails, investigate before moving F1."
