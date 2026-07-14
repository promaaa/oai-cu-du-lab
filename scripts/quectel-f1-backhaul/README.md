# Quectel F1 Backhaul — Scripts and Configs

This directory contains the canonical scripts and configuration templates for
implementing and validating F1-over-Quectel backhaul in the OAI CU/DU split lab.

## Purpose

Move the minipc access DU F1-C/F1-U from the Ethernet baseline to a Quectel
RM500Q-GL + WireGuard overlay path, while preserving:

- One OAI 5GC and one OAI CU on `serber-firecell`.
- A monolithic firecell donor gNB on `serber-firecell` for the outside Quectel modem.
- A minipc access DU on `serber-minipc` for the Nothing Phone.
- USRP B210 serial `8002816` for the minipc access cell only.
- Management SSH connectivity on Ethernet/WiFi.
- Clean rollback to Ethernet F1 at any time.

## Architecture

```
Nothing Phone
    |
    | n78, minipc USRP B210 serial 8002816
    v
serber-minipc (access DU)
  ├─ USRP B210 → access cell only (PCI 0, TAC 1, DU ID 0xe01)
  ├─ Quectel RM500Q-GL outside cage → wwan0
  └─ wg-quectel-f1 (10.250.0.2/30)
       |
       | minipc F1-C SCTP + F1-U UDP/2153 in WireGuard UDP over Quectel
       v
serber-firecell
  ├─ OAI 5GC
  ├─ OAI CU for the minipc access DU
  ├─ monolithic firecell donor gNB + outside USRP (PCI 1, TAC 2)
  │    └─ serves only the Quectel modem; no F1 path
  └─ wg-quectel-f1 (10.250.0.1/30)
```

## Critical Constraint

The Quectel modem must NOT attach to the minipc access cell it is backhauling.
This creates a circular dependency: the access DU needs F1, F1 needs Quectel,
Quectel needs the access cell, and the access cell needs F1.

The supported donor is the firecell monolithic donor gNB, not the minipc B210
and not the failed local-F1 donor-DU experiment. Same-PLMN operation is allowed
only because the donor and access cells have explicit distinct PCI/TAC/cell IDs.

## Scripts

| Script | Purpose |
|---|---|
| `common.sh` | Shared hosts, paths, F1 defaults, SSH helpers, interface detection |
| `00_detect_quectel.sh` | Detect Quectel modem, USB, ModemManager, interfaces |
| `01_check_quectel_connectivity.sh` | QMI data session, IP, route to CU, non-recursive donor check |
| `02_validate_independent_donor.sh` | Fail-closed AT/packet gate for firecell/non-recursive donor proof |
| `02_setup_wireguard_firecell.sh` | WireGuard server on serber-firecell (generates key locally) |
| `03_setup_wireguard_minipc.sh` | WireGuard client on serber-minipc over Quectel (generates key locally) |
| `04_validate_backhaul_path.sh` | Ping, SCTP port check, WireGuard tunnel validation |
| `05_generate_quectel_f1_configs.sh` | Generate firecell CU and minipc access DU WireGuard-F1 configs |
| `05_start_core.sh` | Start OAI 5G Core Network on serber-firecell |
| `06_start_cu_quectel.sh` | Start the CU bound to `10.250.0.1` without killing the donor gNB |
| `06_start_firecell_donor_du_quectel.sh` | Deprecated fail-closed shim for the removed donor-DU path |
| `07_start_du_quectel.sh` | Start minipc access DU with WireGuard F1 and B210 access |
| `08_validate_f1.sh` | Validate donor gNB service plus minipc F1-C/F1-U over Quectel/WireGuard |
| `09_rollback_to_ethernet.sh` | Stop Quectel/WireGuard F1 and restore Ethernet baseline |

## Deployment Sequence

```bash
# Phase 1: discovery and generated split configs
./scripts/quectel-f1-backhaul/00_detect_quectel.sh
./scripts/quectel-f1-backhaul/05_generate_quectel_f1_configs.sh

# Phase 2: firecell core and monolithic donor gNB
./scripts/quectel-f1-backhaul/05_start_core.sh
# Start the firecell monolithic donor gNB by the TUI, or use the documented
# lab command for:
# /home/serber/monolithic/openairinterface5g/.../gnb-firecell-donor-single-core-51prb.conf

# Phase 3: Quectel PDU through the firecell donor gNB
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh

# Phase 4: WireGuard over Quectel and route validation
./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
# Note the MINIPC_PUBLIC_KEY from output
MINIPC_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/02_setup_wireguard_firecell.sh
# Note the FIRECELL_PUBLIC_KEY from output
FIRECELL_PUBLIC_KEY=<key> ./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
./scripts/quectel-f1-backhaul/04_validate_backhaul_path.sh

# Phase 5: firecell CU and minipc access DU over wg-quectel-f1
./scripts/quectel-f1-backhaul/06_start_cu_quectel.sh
./scripts/quectel-f1-backhaul/07_start_du_quectel.sh

# Phase 6: packet-gated validation
./scripts/quectel-f1-backhaul/08_validate_f1.sh
# Register Nothing Phone and measure throughput
```

Do not claim PASS unless tcpdump proves minipc access DU F1-C SCTP and F1-U
UDP/2153 on `wg-quectel-f1`, WireGuard outer UDP on `wwan0`, the firecell
monolithic donor gNB is in service for the Quectel modem, and no minipc F1 is
visible on Ethernet/WiFi.

## Rollback

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```

## Security Rules

- WireGuard private keys: generated locally, never committed to Git.
- No UE authentication values, IMSI, Ki, OPc in this directory.
- No passwords or SSH credential strings in scripts.
- SSH access: key-based auth or agent, no `sshpass`.
- Logs and captures: gitignored, sanitized before any external sharing.

## Reference

- `conf/quectel-f1-backhaul/wireguard-template.conf` — WireGuard config template
- `conf/quectel-f1-backhaul/cu-quectel-f1-template.conf` — CU OAI config template
- `conf/quectel-f1-backhaul/du-quectel-f1-template.conf` — DU OAI config template
- `docs/QUECTEL_BACKHAUL.md` — Canonical topology, proof requirements, and current limitation
- `docs/TROUBLESHOOTING.md` — Recovery and symptom-based diagnosis
