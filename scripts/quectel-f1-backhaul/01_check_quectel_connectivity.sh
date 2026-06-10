#!/usr/bin/env bash
# 01_check_quectel_connectivity.sh — Verify wwan0 has IP, packet service, and route to serber-firecell
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  source "$SCRIPT_DIR/common.sh"
else
  echo "[!] common.sh not found"
  exit 1
fi

log "=== Phase 2: Quectel Connectivity Check on $DU_HOST ==="
log "Purpose: verify wwan0 IP, packet service, internet, and route to CU"
log ""

# Load lab.env for firecell monolithic donor-gNB confirmation
if [ -f "$REPO_BASE/conf/local/lab.env" ]; then
  # shellcheck source=conf/local/lab.env
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null || true
fi

ssh_host "$DU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

QUECTEL_IFACE='${QUECTEL_IFACE}'
QUECTEL_MGMT_DEV='${QUECTEL_MGMT_DEV:-/dev/cdc-wdm2}'
QUECTEL_APN='${QUECTEL_APN}'
CU_MGMT_IP='${CU_MGMT_IP}'
WG_CU_IP='${WG_CU_IP}'

# --- Detect Quectel interface if not set ---
if [ -z \"\$QUECTEL_IFACE\" ] || [ \"\$QUECTEL_IFACE\" = 'wwan0' ]; then
  QUECTEL_IFACE=\$(bash -lc '$detect_quectel_iface_cmd' 2>/dev/null | head -1 || echo '')
fi

if [ -z \"\$QUECTEL_IFACE\" ]; then
  warn 'No Quectel data interface detected. Run 00_detect_quectel.sh first.'
  exit 1
fi

log \"Quectel data interface: \$QUECTEL_IFACE\"

# --- Detect management device if not set ---
if [ -z \"\$QUECTEL_MGMT_DEV\" ] || [ \"\$QUECTEL_MGMT_DEV\" = '/dev/cdc-wdm2' ]; then
  QUECTEL_MGMT_DEV=\$(ls /dev/cdc-wdm* 2>/dev/null | tail -1 || echo '')
fi

if [ -z \"\$QUECTEL_MGMT_DEV\" ]; then
  warn 'No /dev/cdc-wdm* device found'
else
  log \"QMI management device: \$QUECTEL_MGMT_DEV\"
fi

# --- Check if wwan0 already has an IP ---
log '--- wwan0 IP state ---'
IP_ADDR=\$(ip -4 -o addr show dev \"\$QUECTEL_IFACE\" 2>/dev/null | awk '{print \$4}' | cut -d/ -f1 || true)
if [ -n \"\$IP_ADDR\" ]; then
  log \"wwan0 already has IP: \$IP_ADDR\"
else
  log 'wwan0 has no IP — attempting QMI data session...'

  # Bring interface up
  sudo ip link set \"\$QUECTEL_IFACE\" down 2>/dev/null || true
  # Set raw IP mode for QMI
  if [ -e \"/sys/class/net/\$QUECTEL_IFACE/qmi/raw_ip\" ]; then
    echo Y | sudo tee /sys/class/net/\$QUECTEL_IFACE/qmi/raw_ip >/dev/null
  fi
  sudo ip link set \"\$QUECTEL_IFACE\" up

  # Try ModemManager connect
  if command -v mmcli >/dev/null 2>&1; then
    MODEMS=\$(mmcli -L 2>/dev/null | grep -c 'Modem' || echo 0)
    if [ \"\$MODEMS\" -gt 0 ]; then
      MODEM_IDX=\$(mmcli -L 2>/dev/null | grep -oP 'Modem/\d+' | head -1 | grep -oP '\d+' || echo 0)
      log \"Attempting ModemManager connect on modem /\$MODEM_IDX with APN '\$QUECTEL_APN'\"
      sudo mmcli -m \"\$MODEM_IDX\" --simple-connect=\"apn=\$QUECTEL_APN,ip-type=ipv4\" 2>/dev/null || true
      sleep 3
    fi
  fi

  # Try qmicli direct
  if [ -n \"\$QUECTEL_MGMT_DEV\" ] && command -v qmicli >/dev/null 2>&1; then
    log 'Attempting QMI data session via qmicli...'
    sudo qmicli -d \"\$QUECTEL_MGMT_DEV\" --device-open-proxy \
      --wds-start-network=\"apn=\$QUECTEL_APN,ip-type=ipv4\" \
      --client-no-release-cid 2>/dev/null || true
    sleep 3
  fi

  IP_ADDR=\$(ip -4 -o addr show dev \"\$QUECTEL_IFACE\" 2>/dev/null | awk '{print \$4}' | cut -d/ -f1 || true)
  if [ -n \"\$IP_ADDR\" ]; then
    log \"After QMI attempt, wwan0 IP: \$IP_ADDR\"
  else
    warn 'wwan0 still has no IP. QMI data session may have failed.'
    warn 'Check: SIM active? APN correct? Network registered? ModemManager credentials?'
  fi
fi

# --- Show interface state ---
log '--- Current wwan0 interface state ---'
ip -br addr show dev \"\$QUECTEL_IFACE\" || true
ip route show dev \"\$QUECTEL_IFACE\" || true

# --- Packet service and signal info ---
if [ -n \"\$QUECTEL_MGMT_DEV\" ] && command -v qmicli >/dev/null 2>&1; then
  log '--- QMI packet service status ---'
  sudo qmicli -d \"\$QUECTEL_MGMT_DEV\" --device-open-proxy \
    --wds-get-packet-service-status 2>/dev/null || true

  log '--- QMI current settings ---'
  sudo qmicli -d \"\$QUECTEL_MGMT_DEV\" --device-open-proxy \
    --wds-get-current-settings 2>/dev/null || true

  log '--- QMI signal strength ---'
  sudo qmicli -d \"\$QUECTEL_MGMT_DEV\" --device-open-proxy \
    --nas-get-signal-strength 2>/dev/null || true
fi

# --- Connectivity tests ---
log '--- Internet connectivity via wwan0 ---'
if [ -n \"\$IP_ADDR\" ]; then
  ping -I \"\$QUECTEL_IFACE\" -c 3 1.1.1.1 2>/dev/null && log 'ICMP to 1.1.1.1: OK' || warn 'ICMP to 1.1.1.1: FAIL'
  curl --interface \"\$QUECTEL_IFACE\" -4 --max-time 10 ifconfig.me 2>/dev/null && log 'Public IP: OK' || warn 'Public IP check: FAIL'
else
  warn 'Skipping internet tests — no IP on wwan0'
fi

log '--- Route to serber-firecell management IP ---'
ip route get \"\$CU_MGMT_IP\" || true

log '--- Route to WireGuard endpoint ---'
ip route get \"${FIRECELL_WG_ENDPOINT_IP}\" || true

if [ -n \"\$IP_ADDR\" ]; then
  log '--- Ping serber-firecell from wwan0 ---'
  ping -I \"\$QUECTEL_IFACE\" -c 3 \"\$CU_MGMT_IP\" 2>/dev/null && log 'serber-firecell reachable via wwan0' || warn 'serber-firecell NOT reachable via wwan0'
fi

log '--- Ping WireGuard CU endpoint ---'
if [ -n \"\$IP_ADDR\" ]; then
  ping -I \"\$QUECTEL_IFACE\" -c 3 \"\$WG_CU_IP\" 2>/dev/null && log \"\$WG_CU_IP reachable via wwan0\" || warn \"\$WG_CU_IP NOT reachable via wwan0\"
fi

log '=== Connectivity check complete ==='
log ''
log 'Next step:'
log '  - If wwan0 has an IP and CU is reachable, proceed to 02_setup_wireguard_firecell.sh'
log '  - If wwan0 has no IP, investigate: SIM, APN, ModemManager, QMI bearer'
log '  - If modem registers on the local OAI cell (same DU access cell), STOP: circular dependency'
"
