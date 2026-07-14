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
STATE_ROOT="${OAI_LAB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/oai-cu-du-lab}"
OUT_DIR="$STATE_ROOT/runs/${STAMP}_split_performance_window"

if [[ -f "$REPO_ROOT/conf/local/lab.env" ]]; then
  # Sourcing lab.env which contains CU_HOST, DU_HOST, etc.
  # Ignore unbound variable checks for variables set in lab.env
  set +u
  source "$REPO_ROOT/conf/local/lab.env"
  set -u
fi

FIRECELL="${CU_HOST:-serber@10.76.170.38}"
MINIPC="${DU_HOST:-serber-pi}"
FIRECELL_IP="${CU_HOST##*@}"
FIRECELL_IP="${FIRECELL_IP:-10.76.170.38}"

CU_OAI="${CU_OAI_DIR:-/home/serber/cu-du-minipc-backhaul/source/openairinterface5g}"
DU_OAI="${DU_OAI_DIR:-/home/serber/cu-du/source/openairinterface5g}"
CU_LOG="${CU_LOG:-/tmp/oai-cu-ethernet.log}"
DU_LOG="${DU_LOG:-/tmp/oai-du-ethernet.log}"

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
for iface in eth0 enp6s0 enp2s0 enp4s0 wlp3s0 oai-cn5g test-gre wwan0; do
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
  awk -v start="$start_line" 'NR >= start { print }' "$file" | grep -Ei 'F1|SCTP|GTP|UE|registration|PWS|SIB8|MCS|MCSDBG|CQI|CSI|PUCCH|HARQ|BLER|round|RSRP|SNR|throughput|error|assert|timeout|drop|retrans|LCID' | tail -5000 || true
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

ssh "${ssh_opts[@]}" "$MINIPC" "python3 - $DU_LOG_START $DU_LOG" >"$OUT_DIR/measurements/du-scheduler-summary.txt" <<'PY'
import re
import sys

start_line = int(sys.argv[1])
log_file = sys.argv[2]

dlsch = {}  # rnti -> list of samples
lcid4 = {}  # rnti -> list of samples
lcid5 = {}  # rnti -> list of samples

with open(log_file, 'r', encoding='utf-8', errors='replace') as f:
    for idx, line in enumerate(f, 1):
        if idx < start_line:
            continue
        # Parse DLSCH
        m = re.search(r"UE ([0-9a-fA-F]+).*dlsch_rounds (\d+)/(\d+)/(\d+)/(\d+).*BLER ([0-9.]+) MCS \(1\) (\d+)", line)
        if m:
            rnti = m.group(1)
            rounds = tuple(int(m.group(i)) for i in (2, 3, 4, 5))
            bler = float(m.group(6))
            mcs = int(m.group(7))
            if rnti not in dlsch:
                dlsch[rnti] = []
            dlsch[rnti].append((rounds, bler, mcs))
        # Parse LCID
        m = re.search(r"UE ([0-9a-fA-F]+): LCID 4: TX\s+(\d+) RX\s+(\d+) bytes", line)
        if m:
            rnti = m.group(1)
            if rnti not in lcid4:
                lcid4[rnti] = []
            lcid4[rnti].append((int(m.group(2)), int(m.group(3))))
        m = re.search(r"UE ([0-9a-fA-F]+): LCID 5: TX\s+(\d+) RX\s+(\d+) bytes", line)
        if m:
            rnti = m.group(1)
            if rnti not in lcid5:
                lcid5[rnti] = []
            lcid5[rnti].append((int(m.group(2)), int(m.group(3))))

print("# DU scheduler summary from remote log parser")
all_rntis = set(dlsch.keys()) | set(lcid4.keys()) | set(lcid5.keys())
print(f"active_rntis={','.join(all_rntis)}")
for rnti in sorted(all_rntis):
    print(f"\n[UE {rnti}]")
    samples = dlsch.get(rnti, [])
    print(f"dlsch_samples={len(samples)}")
    if samples:
        r0 = samples[-1][0][0] - samples[0][0][0]
        r1 = samples[-1][0][1] - samples[0][0][1]
        mcs_min = min(s[2] for s in samples)
        mcs_max = max(s[2] for s in samples)
        avg_bler = sum(s[1] for s in samples) / len(samples)
        print(f"dlsch_round0_delta={r0}")
        print(f"dlsch_round1_delta={r1}")
        print(f"dl_mcs_min={mcs_min}")
        print(f"dl_mcs_max={mcs_max}")
        print(f"dl_bler_avg={avg_bler:.4f}")
    
    l4 = lcid4.get(rnti, [])
    print(f"lcid4_samples={len(l4)}")
    tx4_delta = 0
    if l4:
        tx4_delta = l4[-1][0] - l4[0][0]
        rx4_delta = l4[-1][1] - l4[0][1]
        print(f"lcid4_tx_delta_bytes={tx4_delta}")
        print(f"lcid4_rx_delta_bytes={rx4_delta}")
        
    l5 = lcid5.get(rnti, [])
    print(f"lcid5_samples={len(l5)}")
    tx5_delta = 0
    if l5:
        tx5_delta = l5[-1][0] - l5[0][0]
        rx5_delta = l5[-1][1] - l5[0][1]
        print(f"lcid5_tx_delta_bytes={tx5_delta}")
        print(f"lcid5_rx_delta_bytes={rx5_delta}")
    
    active = (tx4_delta >= 1_000_000) or (tx5_delta >= 1_000_000)
    print(f"dl_drb_activity={'active' if active else 'low_or_idle'}")
PY

ssh_capture "$FIRECELL" "split core filtered logs" "set +e
for container in oai-cn5g-minipc-oai-amf-1 oai-cn5g-minipc-oai-smf-1 oai-cn5g-minipc-oai-upf-1; do
  echo \"--- docker logs \$container ---\"
  docker logs \"\$container\" --tail 160 2>&1 | grep -Ei 'gNB|UE|PDU|session|DNN|UPF|TEID|register|reject|fail|error|warn' || true
done" "$OUT_DIR/logs/core-filtered.log"

echo "Collection complete: $OUT_DIR"
echo "Reminder: keep this runtime evidence ignored unless sanitized excerpts are intentionally copied into a tracked report."
