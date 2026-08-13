# Baselines

Last reconciled: 2026-08-13.

The MiniPC Ethernet CU/DU path with SIB8 remains the rollback baseline. Each
final setup was exercised in 20 accepted deployment and end-to-end service
trials. The throughput values below are arithmetic means. Because the
cross-setup software, host, and RF state were not held uniform, they establish
per-setup repeatability rather than an intrinsic ranking of transports. The
complete chronology is in `docs/evidence/BENCHMARKS.md`.

| Scenario | Role | Accepted result | Record |
|---|---|---:|---|
| Monolithic x86 | Reference only | 190 Mb/s mean | `X86-MONO-190` |
| Tuned x86 Ethernet CU/DU + SIB8 | Canonical rollback | 100 Mb/s mean | `X86-ETH-100` |
| x86 Wi-Fi/GRE CU/DU + SIB8 | Wireless reference | 52 Mb/s mean | `X86-GRE-52` |
| x86 Quectel/WireGuard F1 | Cellular-backhaul reference | 78 Mb/s mean | `X86-QWG-78` |
| Raspberry Pi 5 Ethernet CU/DU | Lightweight candidate | 21 Mb/s mean | `PI-ETH-21` |
| Raspberry Pi 5 Wi-Fi/GRE CU/DU | Lightweight candidate | 13 Mb/s mean | `PI-GRE-13` |
| Raspberry Pi 5 Quectel/WireGuard F1 | Lightweight candidate | 48 Mb/s mean | `PI-QWG-48` |
| Jetson Ethernet CU/DU | Embedded candidate | 7.3 Mb/s mean | `JETSON-ETH-7.3` |
| Jetson Quectel/WireGuard, intermediate | Chronology only | about 40-44 Mb/s | `JETSON-QWG-INT-44` |
| Jetson Quectel/WireGuard, final | Embedded target | 68 Mb/s mean | `JETSON-QWG-FINAL-68` |

The final Jetson record supersedes, but does not erase, the intermediate
40-44 Mb/s state. The final clean launch used the corrected runtime and
scheduler configuration recorded in the benchmark ledger.

## BLER-dominant observation

Scheduler instrumentation directly observed filtered BLER outside the default
adaptation window, repeated MCS reduction, and a floor at MCS 5. This identifies
the BLER-controller mismatch as the dominant observed mechanism. After the DL
target window was changed from 0.05--0.15 to 0.25--0.35, the dominant MCS moved
from 5 to 24--27 in the instrumented window. The final tuned x86 Ethernet setup
averaged 100 Mb/s over 20 repetitions. This remains an end-to-end configuration
result rather than a universal BLER optimum.

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

PWS acceptance additionally requires the patch digest and ordered CU-F1-DU-UE
gates in `docs/evidence/PWS-F1.md`.
