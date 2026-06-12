#!/usr/bin/env bash
# 07_start_du_quectel.sh — Start DU on serber-minipc with Quectel/WireGuard F1 binding and B210 access
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
DU_LOG="${DU_QUECTEL_LOG:-$DU_LOG}"

log "=== Phase 5c: Starting minipc access DU with Quectel/WireGuard F1 ==="
log "F1 binding: DU listens on $WG_DU_IP, connects to CU at $WG_CU_IP"
log "Access identity: DU_ID=$ACCESS_DU_ID cell=$ACCESS_NR_CELL_ID PCI=$ACCESS_PCI TAC=$ACCESS_TAC"
log "Access radio: USRP B210 serial $ACCESS_B210_SERIAL (NOT used for backhaul)"
log ""

ssh_host "$DU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

DU_CONF='${DU_QUECTEL_CONF}'
BUILD_DIR='$(remote_oai_build_dir "$MINIPC_OAI_DIR")'
DU_LOG='${DU_LOG}'

# Verify config exists
if [ ! -f \"\$DU_CONF\" ]; then
  warn \"DU config not found: \$DU_CONF\"
  warn 'Key changes: local_n_address=$WG_DU_IP, remote_n_address=$WG_CU_IP'
  warn 'Use -E flag to enable SCTP reuse if needed'
  exit 1
fi

log \"DU config: \$DU_CONF\"
log \"Build dir: \$BUILD_DIR\"
log \"Log file: \$DU_LOG\"

# Stop only an existing minipc access DU launched with this config.
log 'Stopping any existing minipc access DU process by config path...'
pids=\"\$(ps -eo pid=,comm=,args= | awk -v conf=\"\$DU_CONF\" '\$2 == \"nr-softmodem\" && index(\$0, conf) > 0 { print \$1 }')\"
if [ -n \"\$pids\" ]; then echo \"\$pids\" | xargs -r sudo -n kill -9 2>/dev/null || true; fi
sleep 2

# Ensure WireGuard is up
log 'Checking WireGuard interface...'
if ! ip link show '$WG_IF' >/dev/null 2>&1; then
  warn 'WireGuard interface $WG_IF is down. Run 03_setup_wireguard_minipc.sh first.'
  exit 1
fi
sudo wg show '$WG_IF' 2>/dev/null || true

log 'Setting CPU governors to performance for radio timing...'
$performance_governors_cmd

if pgrep -x nr-softmodem >/dev/null; then
  log 'Another nr-softmodem is already running on minipc; access DU start may fail if it owns the B210.'
  pgrep -a nr-softmodem || true
else
  log 'Checking B210 serial $ACCESS_B210_SERIAL before access DU start...'
  uhd_find_devices --args serial='$ACCESS_B210_SERIAL' 2>&1 || sudo -n uhd_find_devices --args serial='$ACCESS_B210_SERIAL' 2>&1 || true
fi

# Verify Quectel is still connected
QUECTEL_IP=\$(ip -4 -o addr show dev '$QUECTEL_IFACE' 2>/dev/null | awk '{print \$4}' | cut -d/ -f1 || true)
if [ -z \"\$QUECTEL_IP\" ]; then
  warn 'Quectel wwan0 has no IP — backhaul may be down'
  warn 'Run 01_check_quectel_connectivity.sh before continuing'
fi

# Start DU with -E (SCTP reuse) and continuous TX for stable TDD RACH/uplink.
log 'Starting DU with Quectel/WireGuard F1 config...'
cd \"\$BUILD_DIR\"
nohup sudo ./nr-softmodem -O \"\$DU_CONF\" --log_config.global_log_level info -E --continuous-tx >\"\$DU_LOG\" 2>&1 </dev/null &
DU_PID=\$!

log \"DU started with PID \$DU_PID\"
sleep 5

# Verify process
if ps -eo pid=,comm=,args= | grep -F \"\$DU_CONF\" | grep -q nr-softmodem; then
  log 'DU is running'
  ps -eo pid=,comm=,args= | grep -F \"\$DU_CONF\" | grep nr-softmodem || true
else
  warn 'DU may not have started. Check log:'
  tail -n 30 \"\$DU_LOG\" 2>/dev/null || true
fi

log ''
log '=== DU started ==='
log 'Log: $DU_HOST:\$DU_LOG'
log 'Next: 08_validate_f1.sh to check F1-C and F1-U'
"
