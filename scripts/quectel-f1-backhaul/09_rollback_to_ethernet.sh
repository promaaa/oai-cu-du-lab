#!/usr/bin/env bash
# 09_rollback_to_ethernet.sh — Stop Quectel/WireGuard F1 and restore Ethernet F1
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

log "=== ROLLBACK: Restoring Ethernet F1 CU/DU ==="
log "This stops Quectel/WireGuard F1 and restarts the Ethernet baseline."
log ""

stop_by_config_cmd='
set -euo pipefail
conf="$1"
pids="$(ps -eo pid=,comm=,args= | awk -v conf="$conf" '\''$2 == "nr-softmodem" && index($0, conf) > 0 { print $1 }'\'')"
if [ -n "$pids" ]; then
  echo "$pids" | xargs -r sudo -n kill -9 2>/dev/null || true
  echo "stopped: $conf"
else
  echo "no matching nr-softmodem for: $conf"
fi
sleep 1
ps -eo pid=,comm=,args= | awk -v conf="$conf" '\''$2 == "nr-softmodem" && index($0, conf) > 0'\'' || true
'

# --- Stop Quectel split processes by exact config path ---
log "--- Stopping minipc access DU by config path ---"
ssh_host "$DU_HOST" "bash -s '$DU_QUECTEL_CONF' <<'REMOTE_STOP'
$stop_by_config_cmd
REMOTE_STOP"

log "--- Stopping firecell CU by config path ---"
ssh_host "$CU_HOST" "bash -s '$CU_QUECTEL_CONF' <<'REMOTE_STOP'
$stop_by_config_cmd
REMOTE_STOP"

log "--- Stopping deprecated firecell donor DU by config path if present ---"
ssh_host "$CU_HOST" "bash -s '$FIRECELL_DONOR_DU_CONF' <<'REMOTE_STOP'
$stop_by_config_cmd
REMOTE_STOP"

log "--- Stopping firecell monolithic donor gNB by config path ---"
ssh_host "$CU_HOST" "bash -s '$FIRECELL_DONOR_PROD_CONF' <<'REMOTE_STOP'
$stop_by_config_cmd
REMOTE_STOP"
ssh_host "$CU_HOST" "bash -s '/tmp/oai-tui-firecell-donor-monolithic-runtime.conf' <<'REMOTE_STOP'
$stop_by_config_cmd
REMOTE_STOP"

# --- Stop WireGuard (leave up for future Quectel attempts) ---
log "--- WireGuard status (keeping configured for future attempts) ---"
ssh_host "$DU_HOST" "sudo wg show '$WG_IF' 2>/dev/null || true"
ssh_host "$CU_HOST" "sudo wg show '$WG_IF' 2>/dev/null || true"

# --- Remove stale Quectel routes that override Ethernet F1 ---
log "--- Removing stale Quectel F1 routes from DU ---"
ssh_host "$DU_HOST" "
set -euo pipefail
log() { printf '[*] %s\n' \"\$*\"; }

sudo ip route del '$CU_MGMT_IP' via '$QUECTEL_GATEWAY' dev '$QUECTEL_IFACE' 2>/dev/null || true
sudo ip route del '$FIRECELL_WG_ENDPOINT_IP' via '$QUECTEL_GATEWAY' dev '$QUECTEL_IFACE' 2>/dev/null || true
sudo ip route del '$OAI_UPF_IP' via '$QUECTEL_GATEWAY' dev '$QUECTEL_IFACE' 2>/dev/null || true
sudo ip rule del from all to '$WG_DU_IP' lookup 9999 2>/dev/null || true
sudo ip rule del from '$WG_DU_IP' lookup 9999 2>/dev/null || true

ip route get '$CU_MGMT_IP'
"

# --- Verify management connectivity ---
log "--- Verifying management connectivity ---"
ssh_host "$DU_HOST" "ping -c 2 '$CU_MGMT_IP' 2>/dev/null && log 'Management path: OK' || warn 'Management path: FAIL'"

# --- Restart Core ---
log "--- Starting Core Network ---"
ssh_host "$CU_HOST" "
set -euo pipefail
cd '$FIRECELL_CORE_DIR'
docker compose -f '$FIRECELL_CORE_COMPOSE' up -d 2>/dev/null || docker-compose -f '$FIRECELL_CORE_COMPOSE' up -d
sleep 10
"

# --- Restart CU with Ethernet config ---
log "--- Starting CU with Ethernet F1 config ---"
ssh_host "$CU_HOST" "
set -euo pipefail
BUILD_DIR='$(remote_oai_build_dir "$FIRECELL_OAI_DIR")'
cd \"\$BUILD_DIR\"
nohup sudo ./nr-softmodem -O '$CU_PROD_CONF' --log_config.global_log_level info >/tmp/oai-cu-ethernet.log 2>&1 </dev/null &
sleep 5
pgrep -a nr-softmodem | grep gnb-cu || echo 'CU may not be running — check /tmp/oai-cu-ethernet.log'
"

# --- Restart DU with Ethernet config ---
log "--- Starting DU with Ethernet F1 config ---"
ssh_host "$DU_HOST" "
set -euo pipefail
BUILD_DIR='$(remote_oai_build_dir "$MINIPC_OAI_DIR")'
cd \"\$BUILD_DIR\"
nohup sudo ./nr-softmodem -O '$DU_PROD_CONF' --log_config.global_log_level info -E >/tmp/oai-du-ethernet.log 2>&1 </dev/null &
sleep 5
pgrep -a nr-softmodem | grep gnb-minipc || echo 'DU may not be running — check /tmp/oai-du-ethernet.log'
"

log ''
log "=== Rollback Complete ==="
log "F1 transport: Ethernet (direct management network)"
log "Expected throughput: ~19-23 Mb/s"
log ""
log "To verify rollback:"
log "  1. Check F1-C SCTP association on port 2153"
log "  2. Register Nothing Phone"
log "  3. Verify throughput ~19-23 Mb/s"
log ""
log "To resume Quectel F1 experiments:"
log "  1. Ensure Quectel donor is non-recursive (firecell donor gNB PCI=$DONOR_PCI/TAC=$DONOR_TAC, not minipc access DU)"
log "  2. Run 01_check_quectel_connectivity.sh"
log "  3. Run 02_setup_wireguard_firecell.sh"
log "  4. Run 03_setup_wireguard_minipc.sh"
log "  5. Proceed through the deployment sequence"
