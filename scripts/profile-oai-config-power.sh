#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/profile-oai-config-power.sh --du=<serber-minipc|serber-pi|serber-jetson> --backhaul=<ethernet|wifi-gre|quectel-wg> [options]

Launch a normal OAI CU/DU configuration through scripts/oai-lab-tui, wait for it
to settle, then collect software-only power telemetry while the configuration is
running.

Options:
  --duration=N       Power collection window in seconds (default: 120)
  --settle=N         Seconds to wait after launch before collecting (default: 30)
  --no-stop          Leave the OAI configuration running after collection
  --force-mcs        Pass --force-mcs to scripts/oai-lab-tui
  --no-jumbo-frames  Pass --no-jumbo-frames to scripts/oai-lab-tui
  --no-clamp-mss     Pass --no-clamp-mss to scripts/oai-lab-tui

Examples:
  scripts/profile-oai-config-power.sh --du=serber-jetson --backhaul=ethernet --duration=180
  scripts/profile-oai-config-power.sh --du=serber-pi --backhaul=quectel-wg --duration=180 --no-stop
  scripts/profile-oai-config-power.sh --du=serber-minipc --backhaul=wifi-gre --settle=45

The output goes under the external lab state directory. Raw per-host
telemetry remains local evidence and should be minimized before committing.
EOF
}

DURATION=120
SETTLE=30
STOP_AFTER=1
DU=""
BACKHAUL=""
TUI_FLAGS=()

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      usage
      exit 0
      ;;
    --duration=*)
      DURATION="${arg#*=}"
      ;;
    --settle=*)
      SETTLE="${arg#*=}"
      ;;
    --du=*)
      DU="${arg#*=}"
      ;;
    --backhaul=*)
      BACKHAUL="${arg#*=}"
      ;;
    --no-stop)
      STOP_AFTER=0
      ;;
    --force-mcs|--no-jumbo-frames|--no-clamp-mss)
      TUI_FLAGS+=("$arg")
      ;;
    *)
      echo "unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$DU" in
  serber-minipc|serber-pi|serber-jetson) ;;
  "")
    echo "--du is required" >&2
    usage >&2
    exit 2
    ;;
  *)
    echo "unsupported --du: $DU" >&2
    exit 2
    ;;
esac

case "$BACKHAUL" in
  ethernet|wifi-gre|quectel-wg) ;;
  "")
    echo "--backhaul is required" >&2
    usage >&2
    exit 2
    ;;
  *)
    echo "unsupported --backhaul: $BACKHAUL" >&2
    exit 2
    ;;
esac

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || (( DURATION < 1 )); then
  echo "--duration must be a positive integer" >&2
  exit 2
fi

if ! [[ "$SETTLE" =~ ^[0-9]+$ ]]; then
  echo "--settle must be a non-negative integer" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
STATE_ROOT="${OAI_LAB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/oai-cu-du-lab}"
OUT_DIR="$STATE_ROOT/runs/${STAMP}_oai_power_profile"
mkdir -p "$OUT_DIR"/{launch,power}

START_CMD=("$REPO_ROOT/scripts/oai-lab-tui" "--du=$DU" "--backhaul=$BACKHAUL" "--start-$BACKHAUL")
if (( ${#TUI_FLAGS[@]} > 0 )); then
  START_CMD+=("${TUI_FLAGS[@]}")
fi
STOP_CMD=("$REPO_ROOT/scripts/oai-lab-tui" "--du=$DU" "--backhaul=$BACKHAUL" "--rollback-caged-quectel")
CLEANED_UP=0

cleanup_after_failure() {
  local status=$?
  if (( status != 0 && STOP_AFTER && CLEANED_UP == 0 )); then
    {
      echo "wrapper failed with exit ${status}; attempting normal stop path"
      "${STOP_CMD[@]}"
    } >"$OUT_DIR/launch/cleanup-after-failure.log" 2>&1 || true
    CLEANED_UP=1
  fi
  exit "$status"
}

trap cleanup_after_failure EXIT

cat >"$OUT_DIR/metadata.json" <<EOF
{
  "started_utc": "$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "du": "$DU",
  "backhaul": "$BACKHAUL",
  "duration_s": $DURATION,
  "settle_s": $SETTLE,
  "stop_after": $STOP_AFTER,
  "method": "normal TUI launch followed by software-only power telemetry"
}
EOF

cat >"$OUT_DIR/notes.md" <<EOF
# OAI Configuration Power Profile

DU: $DU
Backhaul: $BACKHAUL
Duration: ${DURATION}s
Settle: ${SETTLE}s
Stop after collection: $STOP_AFTER

This run starts the normal OAI configuration through \`scripts/oai-lab-tui\`,
waits for the configuration to settle, then collects software-only telemetry.
The resulting watts are for the running scenario, not idle-only.

External DC input measurement is still required before final battery sizing.
EOF

printf 'Launching OAI config: %q ' "${START_CMD[@]}" | tee "$OUT_DIR/launch/start-command.txt"
printf '\n' | tee -a "$OUT_DIR/launch/start-command.txt"

if ! "${START_CMD[@]}" >"$OUT_DIR/launch/start.log" 2>&1; then
  echo "launch failed; see $OUT_DIR/launch/start.log" >&2
  exit 1
fi

if grep -Eq 'Evidence was still written where available|✗|Error:' "$OUT_DIR/launch/start.log"; then
  echo "launch log contains a failure marker; see $OUT_DIR/launch/start.log" >&2
  exit 1
fi

if (( SETTLE > 0 )); then
  echo "Waiting ${SETTLE}s for OAI to settle..."
  sleep "$SETTLE"
fi

echo "Collecting software power profile for ${DURATION}s..."
power_log="$OUT_DIR/power/collector.log"
if ! "$REPO_ROOT/scripts/collect-software-power-profile.sh" "$DURATION" >"$power_log" 2>&1; then
  echo "power collection failed; see $power_log" >&2
  exit 1
fi

POWER_DIR="$(awk '/^Wrote / {print $2}' "$power_log" | tail -1)"
if [[ -n "$POWER_DIR" && -d "$POWER_DIR" ]]; then
  ln -s "$POWER_DIR" "$OUT_DIR/power/software_power_profile"
  cp "$POWER_DIR/summary/software-power-metrics.md" "$OUT_DIR/power/software-power-metrics.md" 2>/dev/null || true
  cp "$POWER_DIR/summary/software-power-profile-summary.md" "$OUT_DIR/power/software-power-profile-summary.md" 2>/dev/null || true
fi

if (( STOP_AFTER )); then
  printf 'Stopping OAI config: %q ' "${STOP_CMD[@]}" >"$OUT_DIR/launch/stop-command.txt"
  printf '\n' >>"$OUT_DIR/launch/stop-command.txt"
  "${STOP_CMD[@]}" >"$OUT_DIR/launch/stop.log" 2>&1 || true
  CLEANED_UP=1
fi

cat >"$OUT_DIR/summary.md" <<EOF
# OAI Configuration Power Profile Summary

DU: $DU
Backhaul: $BACKHAUL

EOF

if [[ -f "$OUT_DIR/power/software-power-metrics.md" ]]; then
  {
    sed -n '3,4p' "$OUT_DIR/power/software-power-metrics.md"
    grep "^| $DU |" "$OUT_DIR/power/software-power-metrics.md" || true
  } >>"$OUT_DIR/summary.md"
  cat >>"$OUT_DIR/summary.md" <<EOF

Full host table: power/software-power-metrics.md
EOF
else
  echo "Power metrics table was not generated. See $power_log." >>"$OUT_DIR/summary.md"
fi

cat >>"$OUT_DIR/summary.md" <<EOF

Interpret these values as software-only running-configuration telemetry. Add
USRP, modem, cooling, and DC-converter estimates until full DC input measurement
is available.
EOF

echo "Wrote $OUT_DIR"
