#!/usr/bin/env bash
# 02_validate_independent_donor.sh — fail-closed donor gate for Quectel F1 backhaul
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  # shellcheck source=common.sh
  source "$SCRIPT_DIR/common.sh"
else
  echo "[!] common.sh not found"
  exit 1
fi

if [ -f "$REPO_BASE/conf/local/lab.env" ]; then
  # shellcheck source=conf/local/lab.env
  set +e
  source "$REPO_BASE/conf/local/lab.env" 2>/dev/null
  set -e
fi

log "=== Decision Gate 1: Quectel Independent Donor Validation ==="
log "Host: $DU_HOST"
log "Interface: $QUECTEL_IFACE"
log "Rejected lab PLMN: ${QUECTEL_REJECT_PLMN_MCC}/${QUECTEL_REJECT_PLMN_MNC}"
if [ -n "${QUECTEL_EXPECTED_DONOR_PCI:-}" ] || [ -n "${QUECTEL_EXPECTED_DONOR_TAC:-}" ]; then
  log "Expected donor PCI/TAC: ${QUECTEL_EXPECTED_DONOR_PCI:-any}/${QUECTEL_EXPECTED_DONOR_TAC:-any}"
fi
log ""

ssh_host "$DU_HOST" "
set -euo pipefail

log() { printf '[*] %s\n' \"\$*\"; }
warn() { printf '[!] %s\n' \"\$*\" >&2; }

QUECTEL_IFACE='${QUECTEL_IFACE}'
QUECTEL_AT_PORT='${QUECTEL_AT_PORT}'
QUECTEL_TEST_IP='${QUECTEL_TEST_IP}'
REJECT_MCC='${QUECTEL_REJECT_PLMN_MCC}'
REJECT_MNC='${QUECTEL_REJECT_PLMN_MNC}'
EXPECTED_PCI='${QUECTEL_EXPECTED_DONOR_PCI}'
EXPECTED_TAC='${QUECTEL_EXPECTED_DONOR_TAC}'
FIRECELL_ENDPOINT='${FIRECELL_WG_ENDPOINT_IP}'

send_at() {
  local port=\"\$1\"
  local cmd=\"\$2\"
  printf '%s\r' \"\$cmd\" |
    timeout 8 sudo -n socat -T 5 - \"\$port\",raw,echo=0,b115200 2>/dev/null || true
}

sanitize() {
  sed -E 's/([A-Fa-f0-9]{10,}|[0-9]{7,})/<redacted>/g; s/(\\+COPS: [^,]*,[^,]*,\")[^\"]+/\\1<redacted>/'
}

detect_at_port() {
  if [ -n \"\$QUECTEL_AT_PORT\" ] && [ -e \"\$QUECTEL_AT_PORT\" ]; then
    printf '%s\n' \"\$QUECTEL_AT_PORT\"
    return 0
  fi

  for port in /dev/ttyUSB4 /dev/ttyUSB3 /dev/ttyUSB2 /dev/ttyUSB1 /dev/ttyUSB0; do
    [ -e \"\$port\" ] || continue
    if send_at \"\$port\" 'AT' | grep -q 'OK'; then
      printf '%s\n' \"\$port\"
      return 0
    fi
  done
  return 1
}

AT_PORT=\"\$(detect_at_port || true)\"
if [ -z \"\$AT_PORT\" ]; then
  warn 'No responsive Quectel AT port found.'
  exit 1
fi
log \"AT port: \$AT_PORT\"

log '--- Sanitized modem status ---'
for cmd in 'AT+CFUN?' 'AT+CPIN?' 'AT+CEREG?' 'AT+CREG?' 'AT+CGREG?' 'AT+COPS?' 'AT+CGATT?' 'AT+CGACT?' 'AT+CGPADDR' 'AT+QENG=\"servingcell\"' 'AT+QNWINFO' 'AT+CEER'; do
  printf '%s\n' \"--- \$cmd\"
  send_at \"\$AT_PORT\" \"\$cmd\" | sanitize
done

STATUS=\"\$(send_at \"\$AT_PORT\" 'AT+QENG=\"servingcell\"' | tr -d '\r' || true)\"
ATTACH=\"\$(send_at \"\$AT_PORT\" 'AT+CGATT?' | tr -d '\r' || true)\"
PDP=\"\$(send_at \"\$AT_PORT\" 'AT+CGPADDR' | tr -d '\r' || true)\"

if echo \"\$STATUS\" | grep -Eq '\"NR5G-SA\"|\"LTE\"|\"WCDMA\"|\"GSM\"'; then
  if echo \"\$STATUS\" | grep -Eq \", *0*\$REJECT_MCC,0*\$REJECT_MNC,\"; then
    if [ -z \"\$EXPECTED_PCI\" ] && [ -z \"\$EXPECTED_TAC\" ]; then
      warn \"Modem is camped on rejected lab PLMN \$REJECT_MCC/\$REJECT_MNC.\"
      warn 'Set expected donor PCI/TAC if this is an independent same-PLMN donor.'
      exit 2
    fi
  fi
fi

if [ -n \"\$EXPECTED_PCI\" ] && ! echo \"\$STATUS\" | grep -Eq \", *\$EXPECTED_PCI,\"; then
  warn \"Serving cell does not match expected donor PCI \$EXPECTED_PCI.\"
  exit 2
fi

if [ -n \"\$EXPECTED_TAC\" ] && ! echo \"\$STATUS\" | grep -Eq \", *\$EXPECTED_TAC,\"; then
  warn \"Serving cell does not match expected donor TAC \$EXPECTED_TAC.\"
  exit 2
fi

if ! echo \"\$ATTACH\" | grep -q '+CGATT: 1'; then
  warn 'Packet attach is not active (expected +CGATT: 1).'
  exit 3
fi

if ! echo \"\$PDP\" | grep -Eq '\\+CGPADDR: [0-9]+,\"?[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+'; then
  warn 'No IPv4 PDP address reported by modem.'
  exit 4
fi

if ! ip -4 addr show dev \"\$QUECTEL_IFACE\" | grep -q 'inet '; then
  warn \"\$QUECTEL_IFACE has no IPv4 address.\"
  exit 5
fi

log '--- Packet proof over Quectel interface ---'
if ping -c 3 -I \"\$QUECTEL_IFACE\" \"\$QUECTEL_TEST_IP\"; then
  log \"Ping to \$QUECTEL_TEST_IP over \$QUECTEL_IFACE: PASS\"
else
  warn \"Ping to \$QUECTEL_TEST_IP over \$QUECTEL_IFACE: FAIL\"
  exit 6
fi

log '--- Firecell endpoint route proof ---'
ip route get \"\$FIRECELL_ENDPOINT\" || true
if ping -c 3 -I \"\$QUECTEL_IFACE\" \"\$FIRECELL_ENDPOINT\"; then
  log \"Ping to WireGuard endpoint \$FIRECELL_ENDPOINT over \$QUECTEL_IFACE: PASS\"
else
  warn \"Ping to WireGuard endpoint \$FIRECELL_ENDPOINT over \$QUECTEL_IFACE: FAIL\"
  exit 7
fi

log 'Independent donor gate: PASS'
"
