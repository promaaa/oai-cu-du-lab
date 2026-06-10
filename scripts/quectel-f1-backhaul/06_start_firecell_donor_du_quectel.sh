#!/usr/bin/env bash
# Deprecated helper.
#
# The canonical Quectel backhaul architecture uses a monolithic firecell donor
# gNB for the Quectel modem, not a donor DU connected over local F1. This file
# is intentionally retained as a fail-closed compatibility shim so stale notes
# or shell history do not accidentally launch the failed donor-DU path.
set -euo pipefail

cat >&2 <<'EOF'
[!] Deprecated path: firecell donor DU local-F1 is not the supported Quectel workflow.
[!] Use the TUI scenario instead:
[!]   ./scripts/oai-lab-tui --start-caged-quectel
[!]
[!] Supported architecture:
[!]   firecell 5GC + firecell CU + monolithic firecell donor gNB
[!]   minipc access DU F1 over wg-quectel-f1
EOF

exit 2
