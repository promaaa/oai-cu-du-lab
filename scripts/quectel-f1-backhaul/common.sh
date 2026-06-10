#!/usr/bin/env bash
# quectel-f1-backhaul common.sh
# Shared hosts, paths, F1/WireGuard defaults, SSH helpers, and interface detection
# No secrets committed; private keys generated locally per host

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_BASE="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Host defaults (can be overridden by conf/local/lab.env) ---
CU_HOST="${CU_HOST:-serber-firecell}"
DU_HOST="${DU_HOST:-serber-minipc}"
CU_MGMT_IP="${CU_MGMT_IP:-10.76.170.38}"
DU_MGMT_IP="${DU_MGMT_IP:-10.76.170.100}"
DU_WIFI_IP="${DU_WIFI_IP:-10.85.168.144}"

# --- OAI paths ---
FIRECELL_CORE_DIR="${FIRECELL_CORE_DIR:-/home/serber/cu-du-minipc/oai-cn5g-minipc}"
FIRECELL_CORE_COMPOSE="${FIRECELL_CORE_COMPOSE:-docker-compose-minipc.yaml}"
FIRECELL_OAI_DIR="${FIRECELL_OAI_DIR:-/home/serber/cu-du-minipc-backhaul/source/openairinterface5g}"
MINIPC_OAI_DIR="${MINIPC_OAI_DIR:-/home/serber/cu-du/source/openairinterface5g}"

# --- OAI config files (production = Ethernet baseline) ---
CU_PROD_CONF="${CU_PROD_CONF:-$FIRECELL_OAI_DIR/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc.conf}"
DU_PROD_CONF="${DU_PROD_CONF:-$MINIPC_OAI_DIR/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf}"
FIRECELL_DONOR_PROD_CONF="${FIRECELL_DONOR_PROD_CONF:-/home/serber/monolithic/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-firecell-donor-single-core-51prb.conf}"
# --- OAI config files (Quectel/WireGuard backhaul) ---
CU_QUECTEL_CONF="${CU_QUECTEL_CONF:-$FIRECELL_OAI_DIR/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc-quectel-backhaul.conf}"
DU_QUECTEL_CONF="${DU_QUECTEL_CONF:-$MINIPC_OAI_DIR/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc-quectel-backhaul.conf}"
# Deprecated: retained only so old rollback commands can stop stale processes.
FIRECELL_DONOR_DU_CONF="${FIRECELL_DONOR_DU_CONF:-$FIRECELL_OAI_DIR/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-du-firecell-donor-local-f1.conf}"

# --- Logs ---
CU_LOG="${CU_LOG:-/tmp/oai-cu-quectel.log}"
DU_LOG="${DU_LOG:-/tmp/oai-du-quectel.log}"
FIRECELL_DONOR_DU_LOG="${FIRECELL_DONOR_DU_LOG:-/tmp/oai-du-firecell-donor-local-f1.log}"
FIRECELL_DONOR_GNB_LOG="${FIRECELL_DONOR_GNB_LOG:-/tmp/oai-firecell-donor-monolithic.log}"

# --- WireGuard ---
WG_IF="${WG_IF:-wg-quectel-f1}"
WG_CU_IP="${WG_CU_IP:-10.250.0.1}"
WG_DU_IP="${WG_DU_IP:-10.250.0.2}"
WG_CIDR="${WG_CIDR:-10.250.0.0/30}"
WG_PORT="${WG_PORT:-51821}"
LOCAL_DONOR_F1_CU_IP="${LOCAL_DONOR_F1_CU_IP:-127.0.0.1}"
LOCAL_DONOR_F1_DU_IP="${LOCAL_DONOR_F1_DU_IP:-127.0.0.2}"
WG_FIRECELL_CONF="${WG_FIRECELL_CONF:-/etc/wireguard/$WG_IF.conf}"
WG_MINIPC_CONF="${WG_MINIPC_CONF:-/etc/wireguard/$WG_IF.conf}"
# Policy routing table to keep F1 traffic on WireGuard while management stays on Ethernet/WiFi
WG_POLICY_TABLE="${WG_POLICY_TABLE:-250}"
WG_POLICY_PREF="${WG_POLICY_PREF:-250}"
# --- WireGuard endpoint for minipc side ---
# If serber-firecell is behind NAT or has no public IP, use the OAI CN bridge IP
# as the wireguard endpoint (minipc initiates the tunnel to a reachable firecell address)
FIRECELL_WG_ENDPOINT_IP="${FIRECELL_WG_ENDPOINT_IP:-192.168.71.129}"
# --- OAI UPF and Core network bridge ---
OAI_UPF_IP="${OAI_UPF_IP:-192.168.71.134}"
OAI_CN5G_BRIDGE_IF="${OAI_CN5G_BRIDGE_IF:-oai-cn5g-minipc}"

# --- Quectel modem ---
QUECTEL_IFACE="${QUECTEL_IFACE:-wwan0}"
# Management device (QMI control port)
QUECTEL_MGMT_DEV="${QUECTEL_MGMT_DEV:-}"
# AT command port used for donor registration checks. Leave empty to auto-detect.
QUECTEL_AT_PORT="${QUECTEL_AT_PORT:-}"
# APN for the Quectel PDU session through the firecell monolithic donor gNB.
# MUST NOT depend on the minipc access cell.
QUECTEL_APN="${QUECTEL_APN:-oai}"
# Local lab PLMN must never be accepted as a donor for F1 backhaul.
QUECTEL_REJECT_PLMN_MCC="${QUECTEL_REJECT_PLMN_MCC:-001}"
QUECTEL_REJECT_PLMN_MNC="${QUECTEL_REJECT_PLMN_MNC:-01}"
# Same-PLMN donors are allowed only when their PCI/TAC is explicit. Defaults
# match the firecell monolithic donor gNB, not the minipc access DU.
QUECTEL_EXPECTED_DONOR_PCI="${QUECTEL_EXPECTED_DONOR_PCI:-1}"
QUECTEL_EXPECTED_DONOR_TAC="${QUECTEL_EXPECTED_DONOR_TAC:-2}"
# Static IP to assign to wwan0 when QMI doesn't assign one
QUECTEL_UE_IP="${QUECTEL_UE_IP:-10.0.0.3}"
QUECTEL_GATEWAY="${QUECTEL_GATEWAY:-10.0.0.1}"
QUECTEL_UE_PREFIX="${QUECTEL_UE_PREFIX:-29}"
QUECTEL_TEST_IP="${QUECTEL_TEST_IP:-1.1.1.1}"

# --- F1 ---
F1_PORT="${F1_PORT:-2153}"
# Backhaul mode: "wireguard" (overlay over Quectel) or "direct" (no overlay, direct IP routing)
BACKHAUL_MODE="${BACKHAUL_MODE:-wireguard}"

# --- CU/DU split identities ---
ACCESS_DU_ID="${ACCESS_DU_ID:-0xe01}"
ACCESS_GNB_ID="${ACCESS_GNB_ID:-0xe00}"
ACCESS_NR_CELL_ID="${ACCESS_NR_CELL_ID:-12345678}"
ACCESS_PCI="${ACCESS_PCI:-0}"
ACCESS_TAC="${ACCESS_TAC:-1}"
ACCESS_B210_SERIAL="${ACCESS_B210_SERIAL:-8002816}"

DONOR_DU_ID="${DONOR_DU_ID:-0xe11}"
DONOR_GNB_ID="${DONOR_GNB_ID:-0xe10}"
DONOR_NR_CELL_ID="${DONOR_NR_CELL_ID:-22345678}"
DONOR_PCI="${DONOR_PCI:-1}"
DONOR_TAC="${DONOR_TAC:-2}"

# --- Logging helpers ---
log() {
  printf '[*] %s\n' "$*"
}

warn() {
  printf '[!] %s\n' "$*" >&2
}

info() {
  printf '[=] %s\n' "$*"
}

# --- SSH helpers ---
# Uses key-based auth or SSH agent; no password strings.
ssh_host() {
  local host="$1"
  shift
  local remote_cmd="$*"
  if [ "$host" = "localhost" ] || [ "$host" = "$(hostname 2>/dev/null || true)" ]; then
    bash -lc "$remote_cmd"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=8 "$host" "$@"
  fi
}

# --- OAI build directory ---
remote_oai_build_dir() {
  local oai_dir="$1"
  printf '%s/cmake_targets/ran_build/build' "$oai_dir"
}

# --- Quectel interface detection ---
detect_quectel_iface_cmd='set -euo pipefail
for dev in wwan0 usb0 rmnet_data0; do
  if ip link show "$dev" >/dev/null 2>&1; then
    echo "$dev"
    exit 0
  fi
done
for path in /sys/class/net/enx* /sys/class/net/wwan* /sys/class/net/rmnet* /sys/class/net/usb*; do
  [ -e "$path" ] || continue
  basename "$path"
  exit 0
done
exit 1'

# --- Quectel IP detection ---
detect_quectel_ip_cmd='set -euo pipefail
iface="${1:-}"
if [ -n "$iface" ]; then
  ip -4 -o addr show dev "$iface" | awk "{print \$4}" | cut -d/ -f1 | head -1
fi'

# --- Guard: require firecell monolithic donor gNB confirmation ---
check_quectel_donor() {
  local donor_flag="${QUECTEL_INDEPENDENT_DONOR:-0}"
  if [ "$donor_flag" != "1" ]; then
    warn "QUECTEL_INDEPENDENT_DONOR is not set to 1 in conf/local/lab.env"
    warn "The Quectel modem must attach through the firecell monolithic donor gNB,"
    warn "never through the minipc access DU it backhauls."
    warn "Same-cell recursion fails because access DU needs F1 -> F1 needs"
    warn "Quectel -> Quectel needs access cell -> access cell needs F1."
    warn ""
    warn "Before proceeding, confirm:"
    warn "  1. The Quectel modem is registered on firecell monolithic donor gNB PCI=$DONOR_PCI/TAC=$DONOR_TAC"
    warn "  2. The modem has obtained an IP address on wwan0"
    warn "  3. The modem can reach the internet without depending on the local access cell"
    warn ""
    warn "Set QUECTEL_INDEPENDENT_DONOR=1 in conf/local/lab.env once confirmed."
    return 1
  fi
  log "Independent donor flag confirmed."
}

# --- Perl-based OAI F1 address update ---
perl_update_oai_f1() {
  local local_ip="$1"
  local remote_ip="$2"
  local if_name="${3:-}"
  cat <<PERL
perl -0pi -e '
  s/(local_s_address\\s*=\\s*")[^"]+(")/\${1}$local_ip\${2}/g;
  s/(remote_s_address\\s*=\\s*")[^"]+(")/\${1}$remote_ip\${2}/g;
  s/(local_n_address\\s*=\\s*")[^"]+(")/\${1}$local_ip\${2}/g;
  s/(remote_n_address\\s*=\\s*")[^"]+(")/\${1}$remote_ip\${2}/g;
  s/(GNB_IPV4_ADDRESS_FOR_NG_AMF\\s*=\\s*")[^"]+(")/\${1}192.168.71.129\${2}/g;
  s/(GNB_IPV4_ADDRESS_FOR_NGU\\s*=\\s*")[^"]+(")/\${1}192.168.71.129\${2}/g;
  s/(local_n_if_name\\s*=\\s*")[^"]+(")/\${1}$if_name\${2}/g if "$if_name" ne "";
' "\$conf"
PERL
}
