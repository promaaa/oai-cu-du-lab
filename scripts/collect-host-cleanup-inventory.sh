#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="experiments/${RUN_ID}_host_cleanup_inventory"
mkdir -p "$OUT_DIR/hosts"

if [ "$#" -gt 0 ]; then
  HOSTS=("$@")
else
  HOSTS=(
    "serber@10.76.170.38"
    "serber@10.76.170.40"
    "serber@10.76.170.18"
  )
fi

SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=8
  -o UserKnownHostsFile=/tmp/oai_cleanup_known_hosts
  -o StrictHostKeyChecking=accept-new
)

safe_name() {
  printf '%s' "$1" | tr '@/:' '___' | tr -c 'A-Za-z0-9_.-' '_'
}

run_remote_inventory() {
  local host="$1"
  ssh "${SSH_OPTS[@]}" "$host" 'bash -s' <<'REMOTE'
set -u

echo "## Host"
hostname || true
date -Is || true
uptime || true

echo
echo "## Kernel"
uname -a || true

echo
echo "## Disk"
df -h || true

echo
echo "## Top-level /home/serber usage"
du -hxd1 /home/serber 2>/dev/null | sort -h || true

echo
echo "## Large top-level scratch areas"
du -hxd1 /tmp /var/log 2>/dev/null | sort -h || true

echo
echo "## Network summary"
ip -br addr 2>/dev/null | sed -n '1,80p' || true
ip route 2>/dev/null | sed -n '1,80p' || true

echo
echo "## OAI processes"
pgrep -a 'nr-softmodem|nr-uesoftmodem|lte-softmodem' || true

echo
echo "## Docker containers"
if command -v docker >/dev/null 2>&1; then
  docker ps -a --format '{{.Names}} {{.Status}}' 2>/dev/null | sort || true
else
  echo "docker not installed"
fi

echo
echo "## Candidate OAI and lab directories"
find /home/serber -maxdepth 4 -type d \
  \( -iname '*openairinterface5g*' -o -iname 'oai-cn5g*' -o -iname 'cu-du*' -o -iname 'monolithic' -o -iname 'nrue' -o -iname '*quectel*' -o -iname '*backhaul*' \) \
  2>/dev/null | sort || true

echo
echo "## Candidate cleanup filenames"
find /home/serber /tmp -xdev -maxdepth 5 \
  \( -name '*.pcap' -o -name '*.pcapng' -o -name '*.log' -o -name 'core.*' -o -name '*.bak' -o -name '*.old' -o -name '*.orig' -o -name '*.tmp' -o -name '.DS_Store' -o -name '*.tar' -o -name '*.tar.gz' -o -name '*.zip' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort || true

echo
echo "## Recent OAI runtime files in /tmp"
find /tmp -maxdepth 1 \
  \( -name 'oai-*' -o -name 'oai_tui_*' -o -name 'oai-tui-*' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort || true
REMOTE
}

{
  echo "# Host Cleanup Inventory"
  echo
  echo "Run: ${RUN_ID}"
  echo "Directory: ${OUT_DIR}"
  echo
  echo "Hosts:"
  for host in "${HOSTS[@]}"; do
    echo "- ${host}"
  done
  echo
  echo "This inventory is read-only and records paths/status only, not file contents."
} >"$OUT_DIR/README.md"

for host in "${HOSTS[@]}"; do
  name="$(safe_name "$host")"
  log="$OUT_DIR/hosts/${name}.txt"
  echo "Collecting $host -> $log"
  if run_remote_inventory "$host" >"$log" 2>&1; then
    echo "OK $host" | tee -a "$OUT_DIR/summary.txt"
  else
    echo "FAILED $host (see $log)" | tee -a "$OUT_DIR/summary.txt"
  fi
done

echo
echo "Inventory written to $OUT_DIR"
