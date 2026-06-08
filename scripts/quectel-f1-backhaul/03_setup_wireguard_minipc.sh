#!/usr/bin/env bash
# 03_setup_wireguard_minipc.sh — Configure WireGuard client on serber-minipc over Quectel backhaul
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
  set +e
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null
  set -e
fi

log "=== Phase 3: WireGuard Setup on $DU_HOST (serber-minipc) ==="
log "Purpose: configure WireGuard tunnel over Quectel wwan0 to serber-firecell"
log ""

check_quectel_donor

# FIRECELL_PUBLIC_KEY can be passed as env var or set interactively
if [ -z "${FIRECELL_PUBLIC_KEY:-}" ]; then
  echo "[?] Enter serber-firecell WireGuard public key (or press Enter to skip peer section):"
  echo "    Run 02_setup_wireguard_firecell.sh first to get the key."
  read -r FIRECELL_PUBLIC_KEY || true
fi

# Optional: explicit Quectel interface override
QUECTEL_IFACE="${QUECTEL_IFACE:-}"
if [ -z "$QUECTEL_IFACE" ]; then
  QUECTEL_IFACE="$(ssh_host "$DU_HOST" "bash -lc '$detect_quectel_iface_cmd'" 2>/dev/null | head -1 || true)"
fi

if [ -z "$QUECTEL_IFACE" ]; then
  warn "Cannot detect Quectel interface. Run 00_detect_quectel.sh and 01_check_quectel_connectivity.sh first."
  exit 1
fi

log "Quectel interface: $QUECTEL_IFACE"
log "WireGuard endpoint: ${FIRECELL_ENDPOINT:-$FIRECELL_WG_ENDPOINT_IP}:$WG_PORT"

ssh_host "$DU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

WG_IF='${WG_IF}'
WG_DU_IP='${WG_DU_IP}'
WG_PORT='${WG_PORT}'
WG_MINIPC_CONF='${WG_MINIPC_CONF}'
FIRECELL_PUBLIC_KEY='${FIRECELL_PUBLIC_KEY}'
FIRECELL_ENDPOINT='${FIRECELL_ENDPOINT:-$FIRECELL_WG_ENDPOINT_IP:$WG_PORT}'
FIRECELL_WG_ENDPOINT_IP='${FIRECELL_WG_ENDPOINT_IP}'
QUECTEL_IFACE='${QUECTEL_IFACE}'
QUECTEL_GATEWAY='${QUECTEL_GATEWAY}'
WG_CU_IP='${WG_CU_IP}'

log 'Installing WireGuard if needed...'
if ! command -v wg >/dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y -qq wireguard-tools 2>/dev/null || warn 'WireGuard already installed'
fi

sudo install -d -m 700 /etc/wireguard

# Generate client private key (locally, never stored in Git)
if [ ! -f /etc/wireguard/\${WG_IF}.key ]; then
  log 'Generating WireGuard private key for \$WG_IF...'
  wg genkey | sudo tee /etc/wireguard/\${WG_IF}.key >/dev/null
  sudo chmod 600 /etc/wireguard/\${WG_IF}.key
else
  log 'WireGuard private key already exists for \$WG_IF'
fi

# Read private key
priv=\$(sudo cat /etc/wireguard/\${WG_IF}.key)

log 'Writing WireGuard client config...'

# Build the config. PreUp ensures the Quectel path is used for the WireGuard endpoint.
# The PreUp captures the current wwan0 IP before bringing up WireGuard and adds a
# specific route so the WireGuard handshake goes over Quectel, not management Ethernet.
cat <<'CONF' | sudo tee \"\$WG_MINIPC_CONF\" >/dev/null
[Interface]
Address = {{WG_DU_IP}}/30
PrivateKey = {{priv}}
# Prevent WireGuard from starting if wwan0 has no IP (anti-fallback guard)
# Policy routing ensures F1 traffic uses WireGuard while management stays on Ethernet/WiFi

{{#if FIRECELL_PUBLIC_KEY}}
[Peer]
PublicKey = {{FIRECELL_PUBLIC_KEY}}
Endpoint = {{FIRECELL_ENDPOINT}}
AllowedIPs = {{WG_CU_IP}}/32
PersistentKeepalive = 25
# Force WireGuard endpoint route through Quectel
PostUp = ip route add {{FIRECELL_WG_ENDPOINT_IP}}/32 via {{QUECTEL_GATEWAY}} dev {{QUECTEL_IFACE}} || true
PostUp = ip rule add from {{WG_DU_IP}} lookup 250 priority 250 || true
PostUp = ip route add default via {{WG_CU_IP}} dev {{WG_IF}} table 250 || true
# Cleanup on teardown
PostDown = ip route del {{FIRECELL_WG_ENDPOINT_IP}}/32 dev {{QUECTEL_IFACE}} 2>/dev/null || true
PostDown = ip rule del from {{WG_DU_IP}} lookup 250 priority 250 2>/dev/null || true
{{/if}}
CONF

# Expand template variables using sed
sudo sed -i \
  "s|{{WG_DU_IP}}|\$WG_DU_IP|g;
   s|{{priv}}|\$priv|g;
   s|{{FIRECELL_PUBLIC_KEY}}|\$FIRECELL_PUBLIC_KEY|g;
   s|{{FIRECELL_ENDPOINT}}|\$FIRECELL_ENDPOINT|g;
   s|{{FIRECELL_WG_ENDPOINT_IP}}|\$FIRECELL_WG_ENDPOINT_IP|g;
   s|{{WG_CU_IP}}|\$WG_CU_IP|g;
   s|{{QUECTEL_IFACE}}|\$QUECTEL_IFACE|g;
   s|{{QUECTEL_GATEWAY}}|\$QUECTEL_GATEWAY|g" \
  \"\$WG_MINIPC_CONF\"

sudo chmod 600 \"\$WG_MINIPC_CONF\"

# Remove template markers from lines that are pure template text
sudo sed -i '/{{/d' \"\$WG_MINIPC_CONF\" 2>/dev/null || true

# Start WireGuard only if Quectel interface has an IP (guard against silent fallback)
QUECTEL_IP=\$(ip -4 -o addr show dev \"\$QUECTEL_IFACE\" 2>/dev/null | awk '{print \$4}' | cut -d/ -f1 | head -1 || true)
if [ -n \"\$QUECTEL_IP\" ]; then
  log \"Quectel has IP \$QUECTEL_IP — starting WireGuard...\"
  sudo wg-quick up \"\$WG_IF\" 2>/dev/null || true
  sudo wg show \"\$WG_IF\" 2>/dev/null || true
else
  warn \"Quectel has no IP (\$QUECTEL_IFACE is down or unregistered) — WireGuard NOT started\"
  warn 'Start WireGuard manually after running 01_check_quectel_connectivity.sh once wwan0 has an IP'
fi

log '--- WireGuard status ---'
sudo wg show 2>/dev/null || warn 'WireGuard not running'
ip -br addr show \"\$WG_IF\" 2>/dev/null || true

log ''
log '=== CLIENT_PUBLIC_KEY ==='
sudo wg show \"\$WG_IF\" public-key 2>/dev/null || sudo sh -c 'wg pubkey < /etc/wireguard/\$WG_IF.key'
log '=== END ==='
"
