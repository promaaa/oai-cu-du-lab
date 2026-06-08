#!/usr/bin/env bash
# 00_detect_quectel.sh — Detect and inventory the Quectel RM500Q-GL modem on serber-minipc
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  source "$SCRIPT_DIR/common.sh"
else
  echo "[!] common.sh not found — run from scripts/quectel-f1-backhaul/"
  exit 1
fi

log "=== Phase 2: Quectel Modem Detection on $DU_HOST ==="
log "Purpose: verify hardware, drivers, ModemManager state, and data interface"
log ""

ssh_host "$DU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

log '--- Hostname ---'
hostname

log '--- USB devices (Quectel) ---'
lsusb | grep -Ei 'quectel|qualcomm|5g|lte|wwan|modem|2c7c' || warn 'No Quectel USB device found'

log '--- USB tty and cdc-wdm devices ---'
ls -la /dev/ttyUSB* 2>/dev/null || true
ls -la /dev/cdc-wdm* 2>/dev/null || true

log '--- Kernel modules (QMI/MBIM/wwan) ---'
lsmod | grep -Ei 'qmi|mbim|wwan|cdc|option|usbnet|rmnet' || true

log '--- dmesg (recent modem entries) ---'
sudo dmesg | grep -Ei 'quectel|qmi|mbim|wwan|cdc|option|ttyUSB|usbnet|rmnet' | tail -n 50 || true

log '--- Network interfaces ---'
ip -br addr
ip link show

log '--- Existing routes ---'
ip route
ip rule

log '--- ModemManager ---'
if command -v mmcli >/dev/null 2>&1; then
  log 'ModemManager available'
  mmcli -L 2>/dev/null || true
  MODEMS=\$(mmcli -L 2>/dev/null | grep -c 'Modem' || true)
  if [ \"\$MODEMS\" -gt 0 ]; then
    for idx in \$(mmcli -L 2>/dev/null | grep -oP 'Modem/\d+' | grep -oP '\d+'); do
      log \"--- Modem /\$idx ---\"
      sudo mmcli -m \"\$idx\" 2>/dev/null || true
    done
  else
    warn 'ModemManager reports 0 modems'
  fi
else
  warn 'ModemManager not installed or not in PATH'
fi

log '--- QMI tools ---'
if command -v qmicli >/dev/null 2>&1; then
  log 'qmicli available'
  for dev in /dev/cdc-wdm*; do
    [ -e \"\$dev\" ] || continue
    log \"--- QMI device: \$dev ---\"
    sudo qmicli -d \"\$dev\" --dms-get-operating-mode 2>/dev/null || true
    sudo qmicli -d \"\$dev\" --nas-get-network-selection-mode 2>/dev/null || true
  done
else
  warn 'qmicli not available'
fi

log '--- MBIM tools ---'
if command -v mbimcli >/dev/null 2>&1; then
  log 'mbimcli available'
  for dev in /dev/cdc-wdm*; do
    [ -e \"\$dev\" ] || continue
    log \"--- MBIM device: \$dev ---\"
    sudo mbimcli -d \"\$dev\" --query-ip-configuration 2>/dev/null || true
  done
else
  warn 'mbimcli not available'
fi

log '--- Quectel wwan0 state ---'
for dev in wwan0 usb0 rmnet_data0 enx* wwan*; do
  if ip link show \"\$dev\" >/dev/null 2>&1; then
    log \"Interface \$dev:\"
    ip -br addr show \"\$dev\" || true
    ip route show dev \"\$dev\" || true
    if [ -e \"/sys/class/net/\$dev/qmi/raw_ip\" ]; then
      log \"  raw_ip: \$(cat /sys/class/net/\$dev/qmi/raw_ip 2>/dev/null || echo unknown)\"
    fi
  fi
done

log '--- Ping test: management path ---'
ping -c 2 $CU_MGMT_IP 2>/dev/null && log 'Management: reachable' || warn 'Management: NOT reachable'

log '=== Detection complete ==='
"