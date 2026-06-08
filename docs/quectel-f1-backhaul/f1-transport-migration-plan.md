# Quectel F1 Transport Configuration

**Status**: target configuration; runtime PASS requires packet-gated validation.

## Target

Quectel F1 backhaul always means:

- one OAI 5GC on `serber-firecell`;
- one OAI CU on `serber-firecell`;
- one firecell donor DU on `serber-firecell`, local F1 only;
- one minipc access DU on `serber-minipc`, F1 over `wg-quectel-f1`;
- Quectel RM500Q-GL attached only to the firecell donor DU.

No monolithic donor gNB is used for this setup.

## Identities

| Role | Host | DU ID | gNB ID | NR Cell ID | PCI | TAC | Radio |
|---|---|---:|---:|---:|---:|---:|---|
| Shared CU | `serber-firecell` | N/A | accepts both DUs | N/A | N/A | N/A | N/A |
| Firecell donor DU | `serber-firecell` | `0xe11` | `0xe10` | `22345678` | `1` | `2` | firecell outside USRP |
| Minipc access DU | `serber-minipc` | `0xe01` | `0xe00` | `12345678` | `0` | `1` | B210 serial `8002816` |

## F1 Transport

| Path | F1-C | F1-U | Interface |
|---|---|---|---|
| Firecell donor DU to CU | `127.0.0.2` -> `127.0.0.1` | `127.0.0.2` -> `127.0.0.1` | `lo`, local only |
| Minipc access DU to CU | `10.250.0.2` -> `10.250.0.1` | `10.250.0.2` -> `10.250.0.1` | `wg-quectel-f1` |
| WireGuard outer path | N/A | N/A | UDP over Quectel `wwan0` |

The CU config binds F1 broadly so it can accept both DUs. Each DU config owns
the path selection: donor DU uses loopback; access DU uses WireGuard.

## Generated Configs

Generated outside the repo:

| File | Host | Purpose |
|---|---|---|
| `gnb-cu-minipc-quectel-backhaul.conf` | `serber-firecell` | shared CU accepting both DUs |
| `gnb-du-firecell-donor-local-f1.conf` | `serber-firecell` | donor DU local-F1 config |
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
./scripts/quectel-f1-backhaul/06_start_cu_quectel.sh
./scripts/quectel-f1-backhaul/06_start_firecell_donor_du_quectel.sh
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh
./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
MINIPC_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/02_setup_wireguard_firecell.sh
FIRECELL_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
./scripts/quectel-f1-backhaul/04_validate_backhaul_path.sh
./scripts/quectel-f1-backhaul/07_start_du_quectel.sh
./scripts/quectel-f1-backhaul/08_validate_f1.sh
```

## Rollback

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```

Rollback stops CU, donor DU, and access DU by exact config path and restarts the
Ethernet CU/DU baseline.
