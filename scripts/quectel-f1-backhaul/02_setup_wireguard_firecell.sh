#!/usr/bin/env bash
# 02_setup_wireguard_firecell.sh — Configure WireGuard server on serber-firecell
# Private key generated locally, never committed to Git
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  source "$SCRIPT_DIR/common.sh"
else
  echo "[!] common.sh not found"
  exit 1
fi

# Load lab.env
if [ -f "$REPO_BASE/conf/local/lab.env" ]; then
  # shellcheck source=conf/local/lab.env
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null || true
fi

# Load MINIPC_PUBLIC_KEY from environment or pass as argument
# e.g.: MINIPC_PUBLIC_KEY=<key> ./02_setup_wireguard_firecell.sh
if [ -z "${MINIPC_PUBLIC_KEY:-}" ]; then
  warn "MINIPC_PUBLIC_KEY not set."
  warn "Run 03_setup_wireguard_minipc.sh first to generate the minipc key and print its public key."
  warn "Then pass it: MINIPC_PUBLIC_KEY=<key> ./02_setup_wireguard_firecell.sh"
  exit 1
fi

log "=== Phase 3: WireGuard Setup on $CU_HOST (serber-firecell) ==="
log "Interface: $WG_IF"
log "WireGuard tunnel IPs: $WG_CU_IP <-> $WG_DU_IP"
log "Port: $WG_PORT"
log "Endpoint: minipc public key ends in ...${MINIPC_PUBLIC_KEY: -8}"
log ""

ssh_host "$CU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

WG_IF='${WG_IF}'
WG_CU_IP='${WG_CU_IP}'
WG_PORT='${WG_PORT}'
WG_FIRECELL_CONF='${WG_FIRECELL_CONF}'
OAI_UPF_IP='${OAI_UPF_IP}'
OAI_CN5G_BRIDGE_IF='${OAI_CN5G_BRIDGE_IF}'
QUECTEL_UE_IP='${QUECTEL_UE_IP}'
MINIPC_PUBLIC_KEY='${MINIPC_PUBLIC_KEY}'

log 'Installing WireGuard if needed...'
if ! command -v wg >/dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y -qq wireguard-tools 2>/dev/null || warn 'WireGuard already installed or apt unavailable'
fi

sudo install -d -m 700 /etc/wireguard

# Generate server private key (locally, never stored in Git)
if [ ! -f /etc/wireguard/\${WG_IF}.key ]; then
  log 'Generating WireGuard private key for $WG_IF...'
  wg genkey | sudo tee /etc/wireguard/\${WG_IF}.key >/dev/null
  sudo chmod 600 /etc/wireguard/\${WG_IF}.key
else
  log 'WireGuard private key already exists for $WG_IF'
fi

# Read private key for config generation
priv=\$(sudo cat /etc/wireguard/\${WG_IF}.key)

log 'Writing WireGuard server config...'
cat <<CONF | sudo tee \"\$WG_FIRECELL_CONF\" >/dev/null
[Interface]
Address = \${WG_CU_IP}/30
ListenPort = \${WG_PORT}
PrivateKey = \${priv}
# Keep management access working: allow SSH over existing interfaces
Table = auto

[Peer]
# serber-minipc WireGuard public key
PublicKey = \${MINIPC_PUBLIC_KEY}
AllowedIPs = \${WG_DU_IP}/32
CONF

sudo chmod 600 \"\$WG_FIRECELL_CONF\"

# Enable IPv4 forwarding for WireGuard tunnel
if ! grep -q 'net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null; then
  echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf >/dev/null
fi
sudo sysctl -p /etc/sysctl.conf 2>/dev/null || true

# Start WireGuard
log 'Starting WireGuard interface...'
sudo wg-quick up \"\$WG_IF\" 2>/dev/null || sudo wg-quick start \"\$WG_IF\" 2>/dev/null || true
sudo systemctl enable --now wg-quick@\"\$WG_IF\" 2>/dev/null || true

sleep 2
log 'WireGuard status:'
sudo wg show \"\$WG_IF\"
log \"Config written to: \$WG_FIRECELL_CONF\"

# Print server public key for minipc setup
echo \"\"
log \"=== SERVCFG_PUBLIC_KEY ===\"
sudo wg show \"\$WG_IF\" public-key
log \"=== END ===\"
log ''
log 'On serber-minipc, run 03_setup_wireguard_minipc.sh with FIRECELL_PUBLIC_KEY set to the above value.'
"
