#!/usr/bin/env bash
# 06_start_cu_quectel.sh — Start CU on serber-firecell with Quectel/WireGuard F1 binding
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

log "=== Phase 5a: Starting shared CU on $CU_HOST ==="
log "F1 binding: shared CU accepts local firecell donor DU and minipc access DU over $WG_IF"
log ""

ssh_host "$CU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

CU_CONF='${CU_QUECTEL_CONF}'
BUILD_DIR='$(remote_oai_build_dir "$FIRECELL_OAI_DIR")'
CU_LOG='${CU_LOG}'

# Verify config exists
if [ ! -f \"\$CU_CONF\" ]; then
  warn \"CU config not found: \$CU_CONF\"
  warn 'Generate it using the OAI config generator or cp from gnb-cu-minipc.conf'
  warn 'Key changes: local_s_address=$WG_CU_IP, remote_s_address=$WG_DU_IP'
  exit 1
fi

log \"CU config: \$CU_CONF\"
log \"Build dir: \$BUILD_DIR\"
log \"Log file: \$CU_LOG\"

# Stop only an existing CU launched with this config. Do not kill the firecell
# donor DU; it intentionally runs on the same host.
log 'Stopping any existing CU process by config path...'
pids=\"\$(ps -eo pid=,comm=,args= | awk -v conf=\"\$CU_CONF\" '\$2 == \"nr-softmodem\" && index(\$0, conf) > 0 { print \$1 }')\"
if [ -n \"\$pids\" ]; then echo \"\$pids\" | xargs -r sudo -n kill -9 2>/dev/null || true; fi
sleep 2

# WireGuard must exist before minipc access DU starts, but the donor DU uses a
# local path. Warn rather than fail here so the local donor can still attach.
log 'Checking WireGuard interface for minipc access DU path...'
if ip link show '$WG_IF' >/dev/null 2>&1; then
  sudo wg show '$WG_IF' 2>/dev/null || true
else
  warn 'WireGuard interface $WG_IF is down. Start it before launching the minipc access DU.'
fi

# Start CU
log 'Starting CU with Quectel/WireGuard F1 config...'
cd \"\$BUILD_DIR\"
nohup sudo ./nr-softmodem -O \"\$CU_CONF\" --log_config.global_log_level info >\"\$CU_LOG\" 2>&1 </dev/null &
CU_PID=\$!

log \"CU started with PID \$CU_PID\"
sleep 5

# Verify process
if ps -eo pid=,comm=,args= | grep -F \"\$CU_CONF\" | grep -q nr-softmodem; then
  log 'CU is running'
  ps -eo pid=,comm=,args= | grep -F \"\$CU_CONF\" | grep nr-softmodem || true
else
  warn 'CU may not have started. Check log:'
  tail -n 30 \"\$CU_LOG\" 2>/dev/null || true
fi

log ''
log '=== CU started ==='
log 'Log: $CU_HOST:\$CU_LOG'
log 'Next: 07_start_du_quectel.sh on serber-minipc'
"
