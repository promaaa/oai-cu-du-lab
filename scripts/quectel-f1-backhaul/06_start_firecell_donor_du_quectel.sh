#!/usr/bin/env bash
# 06_start_firecell_donor_du_quectel.sh — Start the local firecell donor DU.
#
# The donor radio remains on serber-firecell, but its F1 path is local to the
# shared CU and never uses the Quectel/WireGuard tunnel.
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

log "=== Phase 5b: Starting firecell donor DU with local F1 ==="
log "Donor F1: DU $LOCAL_DONOR_F1_DU_IP -> CU $LOCAL_DONOR_F1_CU_IP on serber-firecell"
log "Donor identity: DU_ID=$DONOR_DU_ID gNB_ID=$DONOR_GNB_ID cell=$DONOR_NR_CELL_ID PCI=$DONOR_PCI TAC=$DONOR_TAC"
log ""

ssh_host "$CU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

DU_CONF='${FIRECELL_DONOR_DU_CONF}'
BUILD_DIR='$(remote_oai_build_dir "$FIRECELL_OAI_DIR")'
DU_LOG='${FIRECELL_DONOR_DU_LOG}'

if [ ! -f \"\$DU_CONF\" ]; then
  warn \"Firecell donor DU config not found: \$DU_CONF\"
  warn 'Run 05_generate_quectel_f1_configs.sh first.'
  exit 1
fi

log \"Donor DU config: \$DU_CONF\"
log \"Build dir: \$BUILD_DIR\"
log \"Log file: \$DU_LOG\"

log 'Stopping only existing firecell donor DU processes by config path...'
pids=\"\$(ps -eo pid=,comm=,args= | awk -v conf=\"\$DU_CONF\" '\$2 == \"nr-softmodem\" && index(\$0, conf) > 0 { print \$1 }')\"
if [ -n \"\$pids\" ]; then echo \"\$pids\" | xargs -r sudo -n kill -9 2>/dev/null || true; fi
sleep 2

log 'Starting donor DU with local F1 config...'
cd \"\$BUILD_DIR\"
nohup sudo -n ./nr-softmodem -O \"\$DU_CONF\" --log_config.global_log_level info -E >\"\$DU_LOG\" 2>&1 </dev/null &
DU_PID=\$!
log \"Donor DU start command returned PID \$DU_PID\"
sleep 10

if ps -eo pid=,comm=,args= | grep -F \"\$DU_CONF\" | grep -q nr-softmodem; then
  log 'Donor DU is running'
  ps -eo pid=,comm=,args= | grep -F \"\$DU_CONF\" | grep nr-softmodem || true
else
  warn 'Donor DU may not have started. Recent log follows:'
  tail -n 80 \"\$DU_LOG\" 2>/dev/null || true
  exit 2
fi

log 'Recent donor DU F1/radio evidence:'
tail -n 180 \"\$DU_LOG\" 2>/dev/null | grep -Ei 'F1|SCTP|GTP|UHD|B200|B210|in service|PRACH|RNTI|error|fail|assert|Setup|sync' || true
"

log ""
log "=== firecell donor DU start complete ==="
log "Log: $CU_HOST:$FIRECELL_DONOR_DU_LOG"
