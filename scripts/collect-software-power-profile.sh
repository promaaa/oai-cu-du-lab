#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/collect-software-power-profile.sh [duration-seconds]

Collect a read-only software power profile for the DU candidate hosts.

Default duration: 60 seconds

Environment overrides:
  JETSON_HOST=serber@10.76.170.8
  PI_HOST=serber@10.76.170.18
  MINIPC_HOST=serber-minipc

The script records telemetry exposed by the operating system only. It does not
claim full payload watts unless the host exposes actual rail or input-power
sensors. USRP, modem, fan, and DC converter losses still need external
measurement before final battery sizing.
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
OUT_DIR="$STATE_ROOT/runs/${STAMP}_software_power_profile"

if [[ -f "$REPO_ROOT/conf/local/lab.env" ]]; then
  set +u
  source "$REPO_ROOT/conf/local/lab.env"
  set -u
fi

JETSON_HOST="${JETSON_HOST:-serber@10.76.170.8}"
PI_HOST="${PI_HOST:-serber@10.76.170.18}"
MINIPC_HOST="${MINIPC_HOST:-serber-minipc}"

mkdir -p "$OUT_DIR"/{hosts,summary}

ssh_opts=(-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8)

remote_probe_cmd() {
  local label="$1"
  local duration="$2"
  cat <<EOF
set +e
label='$label'
duration='$duration'
echo "--- collection ---"
echo "label=\$label"
echo "started_utc=\$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "duration_s=\$duration"

echo "--- identity ---"
hostname
uname -a
cat /etc/os-release 2>/dev/null | sed -n '1,8p'

echo "--- load and process snapshot ---"
uptime
nproc 2>/dev/null || true
free -h 2>/dev/null || true
ps -eo pid,ppid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null | sed -n '1,16p'
pgrep -a nr-softmodem 2>/dev/null || true

echo "--- cpu frequency and governors ---"
for p in /sys/devices/system/cpu/cpufreq/policy*; do
  [ -d "\$p" ] || continue
  cpu="\${p##*/}"
  gov=\$(cat "\$p/scaling_governor" 2>/dev/null)
  cur=\$(cat "\$p/scaling_cur_freq" 2>/dev/null)
  min=\$(cat "\$p/scaling_min_freq" 2>/dev/null)
  max=\$(cat "\$p/scaling_max_freq" 2>/dev/null)
  echo "\$cpu governor=\$gov cur_khz=\$cur min_khz=\$min max_khz=\$max"
done

echo "--- thermal sensors ---"
for z in /sys/class/thermal/thermal_zone*; do
  [ -r "\$z/temp" ] || continue
  type=\$(cat "\$z/type" 2>/dev/null)
  temp=\$(cat "\$z/temp" 2>/dev/null)
  echo "\${z##*/} type=\$type temp_millic=\$temp"
done

echo "--- hwmon power-capable sensors ---"
for h in /sys/class/hwmon/hwmon*; do
  [ -d "\$h" ] || continue
  name=\$(cat "\$h/name" 2>/dev/null)
  echo "hwmon=\${h##*/} name=\$name"
  for f in "\$h"/power*_input "\$h"/curr*_input "\$h"/in*_input "\$h"/temp*_input; do
    [ -r "\$f" ] || continue
    echo "  \${f##*/}=\$(cat "\$f" 2>/dev/null)"
  done
done

echo "--- jetson telemetry ---"
command -v nvpmodel >/dev/null 2>&1 && nvpmodel -q 2>/dev/null || true
if command -v tegrastats >/dev/null 2>&1; then
  timeout "\$duration" tegrastats --interval 1000 2>/dev/null || true
else
  echo "tegrastats unavailable"
fi
if [ -d /sys/bus/i2c/drivers/ina3221x ]; then
  find /sys/bus/i2c/drivers/ina3221x -maxdepth 5 -type f \
    \( -name 'in_*_input' -o -name 'curr*_input' -o -name 'power*_input' -o -name 'rail_name' \) \
    -print 2>/dev/null | sort | while read -r f; do
      echo "\$f=\$(cat "\$f" 2>/dev/null)"
    done
fi

echo "--- raspberry pi telemetry ---"
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd measure_temp 2>/dev/null || true
  vcgencmd get_throttled 2>/dev/null || true
  vcgencmd measure_volts core 2>/dev/null || true
  vcgencmd pmic_read_adc 2>/dev/null || true
else
  echo "vcgencmd unavailable"
fi

echo "--- x86 turbostat power window ---"
if command -v turbostat >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  sudo -n turbostat --Summary --quiet --show Busy%,Bzy_MHz,PkgWatt,CorWatt,RAMWatt --interval 1 --num_iterations "\$duration" 2>/dev/null || true
else
  echo "turbostat unavailable or sudo requires a password"
fi

echo "--- x86 rapl energy window ---"
rapl_root=/sys/class/powercap/intel-rapl
if command -v turbostat >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  echo "rapl skipped because turbostat already covered the measurement window"
elif [ -d "\$rapl_root" ]; then
  before=\$(mktemp)
  after=\$(mktemp)
  find "\$rapl_root" -maxdepth 2 -name energy_uj -print 2>/dev/null | sort | while read -r f; do
    echo "\$f \$(cat "\$f" 2>/dev/null)" >> "\$before"
  done
  sleep "\$duration"
  find "\$rapl_root" -maxdepth 2 -name energy_uj -print 2>/dev/null | sort | while read -r f; do
    echo "\$f \$(cat "\$f" 2>/dev/null)" >> "\$after"
  done
  awk -v d="\$duration" '
    NR == FNR { start[\$1] = \$2; next }
    (\$1 in start) {
      delta = \$2 - start[\$1]
      if (delta < 0) delta = delta + 262143328850
      printf "%s delta_uj=%s avg_w=%.3f\\n", \$1, delta, delta / 1000000 / d
    }
  ' "\$before" "\$after"
  rm -f "\$before" "\$after"
else
  echo "intel-rapl unavailable"
  sleep "\$duration"
fi

echo "--- usb and radio visibility ---"
lsusb 2>/dev/null || true
lsusb -t 2>/dev/null || true
command -v uhd_find_devices >/dev/null 2>&1 && uhd_find_devices 2>&1 | sed -n '1,80p' || true

echo "--- network interfaces ---"
ip -br link 2>/dev/null || true
ip -br addr 2>/dev/null || true

echo "--- collection complete ---"
echo "finished_utc=\$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
EOF
}

collect_host() {
  local label="$1"
  local host="$2"
  local file="$OUT_DIR/hosts/${label}.txt"

  {
    printf '# %s\n' "$label"
    printf '# host: %s\n' "$host"
    printf '# collected_at_utc: %s\n\n' "$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')"
    ssh "${ssh_opts[@]}" "$host" "$(remote_probe_cmd "$label" "$DURATION")"
  } >"$file" 2>&1 || {
    {
      printf '\n# collection_failed: %s\n' "$label"
      printf '# exit_code: %s\n' "$?"
      printf '# note: SSH must work non-interactively for software profiling.\n'
    } >>"$file"
  }
}

cat >"$OUT_DIR/notes.md" <<EOF
# Software-only power profile

Started: $(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')
Duration: ${DURATION}s per host

This collection is read-only. It uses only host-exposed software telemetry and
does not collect raw logs, packet captures, subscriber data, keys, or passwords.

Interpretation:

- Jetson INA/tegrastats readings are the strongest software-only source when
  present, but still may not include every external USB/peripheral path.
- Raspberry Pi readings are mostly thermal, throttling, voltage, and PMIC
  observability. Treat them as health/load evidence, not payload watts.
- MiniPC Intel RAPL readings estimate CPU/package energy, not full wall input.
- USRP, modem, fan, and DC converter losses remain planning estimates until an
  inline meter or battery/BMS telemetry is available.
EOF

cat >"$OUT_DIR/metadata.json" <<EOF
{
  "started_utc": "$(date -u --iso-8601=seconds 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "duration_s": ${DURATION},
  "hosts": {
    "serber-jetson": "${JETSON_HOST}",
    "serber-pi": "${PI_HOST}",
    "serber-minipc": "${MINIPC_HOST}"
  },
  "method": "software-only host telemetry; not external DC input measurement"
}
EOF

collect_host "serber-jetson" "$JETSON_HOST" &
pid_jetson=$!
collect_host "serber-pi" "$PI_HOST" &
pid_pi=$!
collect_host "serber-minipc" "$MINIPC_HOST" &
pid_minipc=$!

wait "$pid_jetson" || true
wait "$pid_pi" || true
wait "$pid_minipc" || true

python3 - "$OUT_DIR" <<'PY'
import pathlib
import re
import statistics
import sys

out_dir = pathlib.Path(sys.argv[1])
host_dir = out_dir / "hosts"


def read_host(name):
    path = host_dir / f"{name}.txt"
    if not path.exists():
        return ""
    return path.read_text(errors="replace")


def jetson_vdd_in_w(text):
    values = []
    for match in re.finditer(r"VDD_IN\s+([0-9.]+)mW/", text):
        values.append(float(match.group(1)) / 1000.0)
    return values


def pi_pmic_w(text):
    currents = {}
    volts = {}
    for line in text.splitlines():
        current = re.search(r"^\s*(.+?)_A current\(\d+\)=([0-9.]+)A", line)
        if current:
            currents[current.group(1).strip()] = float(current.group(2))
            continue
        volt = re.search(r"^\s*(.+?)_V volt\(\d+\)=([0-9.]+)V", line)
        if volt:
            volts[volt.group(1).strip()] = float(volt.group(2))
    rails = {
        rail: currents[rail] * volts[rail]
        for rail in sorted(currents)
        if rail in volts
    }
    return rails


def minipc_rapl_w(text):
    values = []
    for match in re.finditer(r"avg_w=([0-9.]+)", text):
        values.append(float(match.group(1)))
    return values


def minipc_turbostat_pkg_w(text):
    values = []
    header = None
    for line in text.splitlines():
        cols = line.split()
        if "PkgWatt" in cols:
            header = cols
            continue
        if header and len(cols) == len(header):
            try:
                pkg_index = header.index("PkgWatt")
                values.append(float(cols[pkg_index]))
            except (ValueError, IndexError):
                continue
    return values


def mean_text(values):
    if not values:
        return ""
    return f"{statistics.mean(values):.2f}"


rows = []

jetson = read_host("serber-jetson")
if "collection_failed" in jetson:
    rows.append(("serber-jetson", "unreachable", "", "SSH collection failed."))
else:
    values = jetson_vdd_in_w(jetson)
    if values:
        rows.append((
            "serber-jetson",
            "Jetson VDD_IN from tegrastats",
            mean_text(values),
            "Host input rail software telemetry; peripherals may still be incomplete.",
        ))
    else:
        rows.append(("serber-jetson", "no power field found", "", "Use raw thermal/load data only."))

pi = read_host("serber-pi")
if "collection_failed" in pi:
    rows.append(("serber-pi", "unreachable", "", "SSH collection failed."))
else:
    rails = pi_pmic_w(pi)
    if rails:
        total = sum(rails.values())
        rows.append((
            "serber-pi",
            "PMIC rail sum from vcgencmd",
            f"{total:.2f}",
            "Partial board rails only; not a full payload input measurement.",
        ))
    else:
        rows.append(("serber-pi", "no PMIC current+voltage pairs", "", "Use throttling and thermal state only."))

minipc = read_host("serber-minipc")
if "collection_failed" in minipc:
    rows.append(("serber-minipc", "unreachable", "", "SSH collection failed."))
else:
    values = minipc_turbostat_pkg_w(minipc)
    if values:
        rows.append((
            "serber-minipc",
            "Intel turbostat PkgWatt",
            mean_text(values),
            "CPU package estimate only; not full wall input or USB peripherals.",
        ))
    else:
        values = minipc_rapl_w(minipc)
        if values:
            rows.append((
                "serber-minipc",
                "Intel RAPL package/domain sum",
                f"{sum(values):.2f}",
                "CPU/package estimate only; not full wall input.",
            ))
        else:
            rows.append(("serber-minipc", "no x86 power telemetry found", "", "Use thermal/load data only."))

summary = out_dir / "summary" / "software-power-metrics.md"
with summary.open("w", encoding="utf-8") as f:
    f.write("# Software-Derived Power Metrics\n\n")
    f.write("| Host | Metric | Software W | Interpretation |\n")
    f.write("|---|---|---:|---|\n")
    for host, metric, watts, note in rows:
        watt_cell = watts if watts else "n/a"
        f.write(f"| {host} | {metric} | {watt_cell} | {note} |\n")
    f.write("\nDo not use these values alone as final battery-sizing inputs. Add USRP, modem, fan, and DC conversion estimates until inline DC measurement is available.\n")
PY

{
  echo "# Software Power Profile Summary"
  echo
  echo "Output directory: $OUT_DIR"
  echo
  echo "| Host | Strongest software metric | Battery-sizing trust | Notes |"
  echo "|---|---|---|---|"
  echo "| serber-jetson | tegrastats / INA rails if present | Medium | Best software-only candidate, still verify full payload later. |"
  echo "| serber-pi | vcgencmd health, PMIC ADC if exposed | Low | Good for throttling and thermal state, weak for watts. |"
  echo "| serber-minipc | Intel RAPL if present | Low-Medium | CPU/package only, not wall power or peripherals. |"
  echo
  if [[ -f "$OUT_DIR/summary/software-power-metrics.md" ]]; then
    echo "Computed software-derived metric table:"
    echo
    sed -n '3,8p' "$OUT_DIR/summary/software-power-metrics.md"
    echo
  fi
  echo
  echo "Review per-host files under hosts/. Replace planning estimates in"
  echo "scripts/drone-du-sizing.py only after deciding which telemetry is credible."
} >"$OUT_DIR/summary/software-power-profile-summary.md"

echo "Wrote $OUT_DIR"
