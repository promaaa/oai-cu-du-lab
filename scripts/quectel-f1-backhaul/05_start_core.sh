#!/usr/bin/env bash
# 05_start_core.sh — Start OAI 5G Core Network on serber-firecell
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

log "=== Phase 3/5: Starting OAI 5G Core Network on $CU_HOST ==="

ssh_host "$CU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

CORE_DIR='${FIRECELL_CORE_DIR}'
COMPOSE='${FIRECELL_CORE_COMPOSE}'

log 'Checking Core Network directory...'
if [ ! -d \"\$CORE_DIR\" ]; then
  warn \"Core Network directory not found: \$CORE_DIR\"
  warn 'Verify path in conf/local/lab.env'
  exit 1
fi

cd \"\$CORE_DIR\"

log 'Starting Core Network containers...'
docker compose -f \"\$COMPOSE\" up -d 2>/dev/null || docker-compose -f \"\$COMPOSE\" up -d

sleep 5
log 'Core containers running:'
docker ps | grep -E 'oai|free5gc|nr-softmodem' || true

log ''
log 'Waiting for AMF to be healthy...'
for i in \$(seq 1 30); do
  AMF_HEALTH=\$(docker ps --filter 'name=.*amf.*' --format '{{.Status}}' 2>/dev/null || echo '')
  if echo \"\$AMF_HEALTH\" | grep -q 'Up'; then
    log \"AMF is up after \${i}s\"
    break
  fi
  sleep 2
done

log ''
log 'Core Network status:'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

log ''
log '=== Core Network started ==='
log 'Next: 06_start_cu_quectel.sh (start CU with WireGuard F1 config)'
"