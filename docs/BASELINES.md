# Baselines

Historical throughput is context, not a current ceiling. A baseline becomes
current only after a controlled rerun records machine and phone gates
separately.

This table tracks fresh acceptance evidence, not whether the operator console
implements a scenario. `docs/STATUS.md` records supported capabilities; a
supported capability may still be `BLOCKED`, `PARTIAL`, or `HISTORICAL` here.

| Scenario | Role | Recorded result | Current classification |
|---|---|---:|---|
| Monolithic OAI | Reference only | about 150 Mb/s historically | `PARTIAL`: machine-side reference reproduced 2026-07-14; phone gates not rerun |
| MiniPC Ethernet CU/DU + SIB8 | Canonical rollback | about 19–23 Mb/s historically | `BLOCKED`: B210 was not on MiniPC during the latest rollback attempt |
| Wi-Fi GRE CU/DU + SIB8 | Wireless candidate | about 12 Mb/s historically | `HISTORICAL`: requires fresh validation |
| Raspberry Pi Ethernet CU/DU | Lightweight candidate | about 18–23 Mb/s historically | `HISTORICAL`: requires fresh validation |
| Jetson Ethernet CU/DU | Embedded candidate | 6.5–7.3 Mb/s in an earlier run | `PARTIAL`: see current status |
| Quectel/WireGuard F1 | Target wireless backhaul | no accepted end-to-end result | `BLOCKED`: canonical donor-DU/access-DU topology not proven |

## OAI source pin

The documented split baseline commit is
`102965a669b9444857c27843ec8ce62780bf9d37`. Every run must record the actual
CU and DU commit and local patch state; a directory name or old binary is not
proof of the pin.

## Full PASS gate

A full scenario PASS requires fresh evidence for:

1. process and core health;
2. NG and applicable F1-C/F1-U paths;
3. RF readiness and timing stability;
4. phone-visible PWS;
5. UE registration;
6. PDU session and external-DN reachability;
7. phone internet;
8. timestamped downlink and uplink throughput;
9. clean stop and residue check;
10. reproducible Ethernet rollback.
