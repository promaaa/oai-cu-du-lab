# Quectel F1 Transport Configuration

**Status**: target configuration; runtime PASS requires packet-gated validation.

## Target

Quectel F1 backhaul always means:

- one OAI 5GC on `serber-firecell`;
- one OAI CU on `serber-firecell`;
- one monolithic firecell donor gNB on `serber-firecell`;
- one minipc access DU on `serber-minipc`, F1 over `wg-quectel-f1`;
- Quectel RM500Q-GL attached only to the firecell monolithic donor gNB.

The failed local-F1 donor-DU setup is not used for this setup.

## Identities

| Role | Host | DU ID | gNB ID | NR Cell ID | PCI | TAC | Radio |
|---|---|---:|---:|---:|---:|---:|---|
| Shared CU | `serber-firecell` | N/A | accepts both DUs | N/A | N/A | N/A | N/A |
| Firecell donor gNB | `serber-firecell` | N/A | `0xe10` | `22345678` | `1` | `2` | firecell outside USRP |
| Minipc access DU | `serber-minipc` | `0xe01` | `0xe00` | `12345678` | `0` | `1` | B210 serial `8002816` |

## F1 Transport

| Path | F1-C | F1-U | Interface |
|---|---|---|---|
| Minipc access DU to CU | `10.250.0.2` -> `10.250.0.1` | `10.250.0.2` -> `10.250.0.1` | `wg-quectel-f1` |
| WireGuard outer path | N/A | N/A | UDP over Quectel `wwan0` |

The CU config binds F1 to the WireGuard CU address. The donor gNB has no F1
path; it attaches to the same 5GC over N2/N3 and serves only the Quectel modem.

## Generated Configs

Generated outside the repo:

| File | Host | Purpose |
|---|---|---|
| `gnb-cu-minipc-quectel-backhaul.conf` | `serber-firecell` | CU bound to `10.250.0.1` |
| `gnb-minipc-quectel-backhaul.conf` | `serber-minipc` | access DU WireGuard-F1 config |
| `/etc/wireguard/wg-quectel-f1.conf` | both hosts | WireGuard over Quectel |

Generate and sanity-check them with:

```bash
./scripts/quectel-f1-backhaul/05_generate_quectel_f1_configs.sh
```

The generator fails closed if required IDs, PCI/TAC values, B210 serial, or F1
addresses are missing.

## Launch Order

```bash
./scripts/quectel-f1-backhaul/05_start_core.sh
# Start the monolithic firecell donor gNB using the TUI or validated lab command.
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh
./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
MINIPC_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/02_setup_wireguard_firecell.sh
FIRECELL_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
./scripts/quectel-f1-backhaul/04_validate_backhaul_path.sh
./scripts/quectel-f1-backhaul/06_start_cu_quectel.sh
./scripts/quectel-f1-backhaul/07_start_du_quectel.sh
./scripts/quectel-f1-backhaul/08_validate_f1.sh
```

## Rollback

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```

Rollback stops CU, donor gNB, and access DU by exact config path and restarts the
Ethernet CU/DU baseline.
