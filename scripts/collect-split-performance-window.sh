#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/collect-split-performance-window.sh [duration-seconds]

Collect a read-only, sanitized evidence window for CU/DU split performance
debugging. The script does not start or stop OAI processes and does not collect
raw packet captures.

Default duration: 60 seconds
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DURATION="${1:-60}"
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || (( DURATION < 1 )); then
  echo "duration must be a positive integer" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
OUT_DIR="$REPO_ROOT/experiments/${STAMP}_split_performance_window"

FIRECELL="serber@10.76.170.38"
MINIPC="serber@10.76.170.100"
FIRECELL_IP="10.76.170.38"

CU_OAI="/home/serber/cu-du-minipc-backhaul/source/openairinterface5g"
DU_OAI="/home/serber/cu-du/source/openairinterface5g"
CU_LOG="/tmp/oai-cu-ethernet.log"
DU_LOG="/tmp/oai-du-ethernet.log"

mkdir -p "$OUT_DIR"/{logs,measurements,system-status}

ssh_opts=(-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8)

ssh_capture() {
  local host="$1"
  local label="$2"
  local cmd="$3"
  local file="$4"

  {
    printf '# %s\n' "$label"
    printf '# host: %s\n' "$host"
    printf '# collected_at_utc: %s\n\n' "$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
    ssh "${ssh_opts[@]}" "$host" "$cmd"
  } >"$file" 2>&1 || {
    {
      printf '\n# collection_failed: %s\n' "$label"
      printf '# exit_code: %s\n' "$?"
    } >>"$file"
  }
}

host_state_cmd() {
  local oai_dir="$1"
  cat <<EOF
set +e
echo "--- hostname ---"
hostname
echo "--- nr-softmodem processes ---"
pgrep -a nr-softmodem || true
echo "--- pinned OAI commit candidate ---"
git -C "$oai_dir" rev-parse HEAD 2>/dev/null || true
echo "--- selected addresses ---"
ip -br addr | sed -n '1,30p'
echo "--- selected routes ---"
ip route | sed -n '1,20p'
echo "--- SCTP/socket summary ---"
ss -s 2>/dev/null || true
echo "--- SCTP listeners/connections ---"
ss -nape 2>/dev/null | grep -Ei 'sctp|38472|2152' || true
EOF
}

link_counters_cmd() {
  cat <<'EOF'
set +e
for iface in enp2s0 enp4s0 wlp3s0 oai-cn5g test-gre wwan0; do
  if ip link show "$iface" >/dev/null 2>&1; then
    echo "--- ip -s link show $iface ---"
    ip -s link show "$iface"
  fi
done
echo "--- ss -s ---"
ss -s 2>/dev/null || true
EOF
}

filtered_log_cmd() {
  local file="$1"
  local start_line="${2:-1}"
  cat <<EOF
set +e
if [[ -r "$file" ]]; then
  echo "--- filtered log: $file ---"
  echo "--- filtered from line: $start_line ---"
  awk -v start="$start_line" 'NR >= start { print }' "$file" | grep -Ei 'F1|SCTP|GTP|UE|registration|PWS|SIB8|MCS|MCSDBG|CQI|CSI|PUCCH|HARQ|BLER|round|RSRP|SNR|throughput|error|assert|timeout|drop|retrans' | tail -1000 || true
else
  echo "log not readable: $file"
fi
EOF
}

remote_log_line_count() {
  local host="$1"
  local file="$2"
  ssh "${ssh_opts[@]}" "$host" "test -r '$file' && wc -l < '$file' || echo 1" 2>/dev/null | tr -dc '0-9' || true
}

cat >"$OUT_DIR/notes.md" <<EOF
# Split performance evidence window

Started: $(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')
Duration: ${DURATION}s

This is a read-only collection. It does not start or stop OAI processes and does
not collect raw packet captures. Review and minimize excerpts before committing
any evidence.
EOF

cat >"$OUT_DIR/metadata.json" <<EOF
{
  "timestamp_utc": "$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "duration_seconds": $DURATION,
  "repo_commit": "$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)",
  "firecell": "$FIRECELL",
  "minipc": "$MINIPC",
  "collector": "scripts/collect-split-performance-window.sh",
  "raw_packet_capture": false
}
EOF

echo "Evidence directory: $OUT_DIR"
echo "Operator note: start sustained downlink traffic before this collector and keep it running for the full ${DURATION}s window."

ssh_capture "$FIRECELL" "firecell pre-window state" "$(host_state_cmd "$CU_OAI")" "$OUT_DIR/system-status/firecell-pre.txt"
ssh_capture "$MINIPC" "minipc pre-window state" "$(host_state_cmd "$DU_OAI")" "$OUT_DIR/system-status/minipc-pre.txt"
ssh_capture "$FIRECELL" "firecell pre-window link counters" "$(link_counters_cmd)" "$OUT_DIR/measurements/firecell-link-pre.txt"
ssh_capture "$MINIPC" "minipc pre-window link counters" "$(link_counters_cmd)" "$OUT_DIR/measurements/minipc-link-pre.txt"

CU_LOG_START="$(remote_log_line_count "$FIRECELL" "$CU_LOG")"
DU_LOG_START="$(remote_log_line_count "$MINIPC" "$DU_LOG")"
CU_LOG_START="${CU_LOG_START:-1}"
DU_LOG_START="${DU_LOG_START:-1}"
{
  printf 'cu_log_start_line=%s\n' "$CU_LOG_START"
  printf 'du_log_start_line=%s\n' "$DU_LOG_START"
} >"$OUT_DIR/logs/window-log-start-lines.txt"

ssh_capture "$MINIPC" "DU to CU ping timing" "ping -c 20 -i 0.2 $FIRECELL_IP || true" "$OUT_DIR/measurements/minipc-to-firecell-ping.txt"

echo "Waiting ${DURATION}s for measurement window..."
sleep "$DURATION"

ssh_capture "$FIRECELL" "firecell post-window link counters" "$(link_counters_cmd)" "$OUT_DIR/measurements/firecell-link-post.txt"
ssh_capture "$MINIPC" "minipc post-window link counters" "$(link_counters_cmd)" "$OUT_DIR/measurements/minipc-link-post.txt"
ssh_capture "$FIRECELL" "firecell post-window state" "$(host_state_cmd "$CU_OAI")" "$OUT_DIR/system-status/firecell-post.txt"
ssh_capture "$MINIPC" "minipc post-window state" "$(host_state_cmd "$DU_OAI")" "$OUT_DIR/system-status/minipc-post.txt"

ssh_capture "$FIRECELL" "CU filtered OAI log" "$(filtered_log_cmd "$CU_LOG" "$CU_LOG_START")" "$OUT_DIR/logs/cu-filtered.log"
ssh_capture "$MINIPC" "DU filtered OAI log" "$(filtered_log_cmd "$DU_LOG" "$DU_LOG_START")" "$OUT_DIR/logs/du-filtered.log"

python3 - "$OUT_DIR/logs/du-filtered.log" >"$OUT_DIR/measurements/du-scheduler-summary.txt" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
dlsch = []
lcid4 = []
for line in path.read_text(errors="replace").splitlines():
    m = re.search(r"dlsch_rounds (\d+)/(\d+)/(\d+)/(\d+).*BLER ([0-9.]+) MCS \(1\) (\d+)", line)
    if m:
        dlsch.append(tuple(int(m.group(i)) for i in (1, 2, 3, 4)) + (float(m.group(5)), int(m.group(6))))
    m = re.search(r"LCID 4: TX\s+(\d+) RX\s+(\d+) bytes", line)
    if m:
        lcid4.append((int(m.group(1)), int(m.group(2))))

print("# DU scheduler summary from filtered measurement-window log")
print(f"dlsch_samples={len(dlsch)}")
if dlsch:
    print(f"dlsch_round0_delta={dlsch[-1][0] - dlsch[0][0]}")
    print(f"dlsch_round1_delta={dlsch[-1][1] - dlsch[0][1]}")
    print(f"dl_mcs_min={min(sample[5] for sample in dlsch)}")
    print(f"dl_mcs_max={max(sample[5] for sample in dlsch)}")
print(f"lcid4_samples={len(lcid4)}")
if lcid4:
    tx_delta = lcid4[-1][0] - lcid4[0][0]
    rx_delta = lcid4[-1][1] - lcid4[0][1]
    print(f"lcid4_tx_delta_bytes={tx_delta}")
    print(f"lcid4_rx_delta_bytes={rx_delta}")
    print(f"dl_drb_activity={'active' if tx_delta >= 1_000_000 else 'low_or_idle'}")
PY

ssh_capture "$FIRECELL" "split core filtered logs" "set +e
for container in oai-cn5g-minipc-oai-amf-1 oai-cn5g-minipc-oai-smf-1 oai-cn5g-minipc-oai-upf-1; do
  echo \"--- docker logs \$container ---\"
  docker logs \"\$container\" --tail 160 2>&1 | grep -Ei 'gNB|UE|PDU|session|DNN|UPF|TEID|register|reject|fail|error|warn' || true
done" "$OUT_DIR/logs/core-filtered.log"

echo "Collection complete: $OUT_DIR"
echo "Reminder: keep this runtime evidence ignored unless sanitized excerpts are intentionally copied into a tracked report."
