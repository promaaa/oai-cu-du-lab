# Quectel IP Backhaul Validation

**Status**: validation procedure for the single-CU firecell donor DU target.

## Objective

Validate that `serber-minipc` can reach the shared CU over WireGuard carried by
the Quectel PDU session, while management Ethernet/WiFi remain available only
for SSH, diagnostics, and rollback.

## Architecture Under Test

```text
firecell donor DU (serber-firecell)
  local F1 only: 127.0.0.2 -> CU 127.0.0.1
  serves Quectel modem outside cage

Quectel RM500Q-GL
  wwan0 PDU session on serber-minipc
  attaches only to firecell donor DU PCI 1 / TAC 2

wg-quectel-f1
  serber-firecell: 10.250.0.1/30
  serber-minipc:   10.250.0.2/30
  outer UDP over wwan0

minipc access DU
  B210 serial 8002816
  F1-C/F1-U over wg-quectel-f1 only
```

## Required Gates

1. Quectel modem has an IPv4 PDU session on `wwan0`.
2. Quectel serving cell matches the donor cell, not the access cell.
3. Route to the WireGuard endpoint uses `wwan0`.
4. `wg-quectel-f1` handshakes and pings both directions.
5. Management Ethernet/WiFi do not carry minipc F1.

## Commands

```bash
./scripts/quectel-f1-backhaul/00_detect_quectel.sh
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh
./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
MINIPC_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/02_setup_wireguard_firecell.sh
FIRECELL_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
./scripts/quectel-f1-backhaul/04_validate_backhaul_path.sh
```

## Expected Evidence

| Check | Expected |
|---|---|
| `wwan0` | IPv4 address from Quectel PDU session |
| Donor cell | PCI `1`, TAC `2`, not access PCI `0` / TAC `1` |
| `ip route get 192.168.71.129` | route via Quectel gateway and `wwan0` |
| `wg show wg-quectel-f1` | fresh handshake and transfer counters |
| tunnel ping | `10.250.0.2` <-> `10.250.0.1` succeeds |
| outer packets | UDP WireGuard packets visible on `wwan0` |

## Failure Handling

If the modem camps on the minipc access cell, stop. That is same-cell recursion.
If `wwan0` has no IP or the route to the WireGuard endpoint does not use
`wwan0`, do not start the minipc access DU. Use rollback if the lab needs to
return to Ethernet F1.
