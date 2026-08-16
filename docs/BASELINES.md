# Baselines

Last reconciled: 2026-08-14.

The MiniPC Ethernet CU/DU path with SIB8 remains the rollback baseline. Each
final setup was exercised in 20 accepted deployment and end-to-end service
trials in the same enclosed laboratory RF environment. The access-cell radio
profile, intended handset, pinned OAI revision, and validation workflow were
held fixed. The DU host and F1 bearer are deliberate configuration variables;
host-specific runtime settings and the named BLER intervention also differ
where recorded. The throughput values below are arithmetic means recomputed
from 20 retained observations per final setup, not a one-factor transport
ranking. The complete series and statistical summary are in
`docs/evidence/throughput-observations.csv` and
`docs/evidence/BENCHMARKS.md`.

| Scenario | Role | Accepted result | Record |
|---|---|---:|---|
| Monolithic x86 | Reference only | 190.7 Mb/s mean | `X86-MONO-FINAL` |
| Tuned x86 Ethernet CU/DU + SIB8 | Canonical rollback | 99.8 Mb/s mean | `X86-ETH-FINAL` |
| x86 Wi-Fi/GRE CU/DU + SIB8 | Wireless reference | 52.0 Mb/s mean | `X86-GRE-FINAL` |
| x86 Quectel/WireGuard F1 | Cellular-backhaul reference | 76.7 Mb/s mean | `X86-QWG-FINAL` |
| Raspberry Pi 5 Ethernet CU/DU | Lightweight candidate | 21.9 Mb/s mean | `PI-ETH-FINAL` |
| Raspberry Pi 5 Wi-Fi/GRE CU/DU | Lightweight candidate | 12.7 Mb/s mean | `PI-GRE-FINAL` |
| Raspberry Pi 5 Quectel/WireGuard F1 | Lightweight candidate | 47.8 Mb/s mean | `PI-QWG-FINAL` |
| Jetson Ethernet CU/DU | Embedded candidate | 10.2 Mb/s mean | `JETSON-ETH-FINAL` |
| Jetson Wi-Fi/GRE CU/DU | Embedded candidate | 8.1 Mb/s mean | `JETSON-GRE-FINAL` |
| Jetson Quectel/WireGuard | Embedded target | 68.4 Mb/s mean | `JETSON-QWG-FINAL` |

## BLER-dominant observation and causal boundary

Scheduler instrumentation directly observed filtered BLER outside the default
adaptation window, repeated MCS reduction, and a floor at MCS 5. This identifies
the BLER-controller mismatch as the dominant observed mechanism. After the DL
target window was changed from 0.05--0.15 to 0.25--0.35, the dominant MCS moved
from 5 to 24--27 in the instrumented window. The radio profile, attenuation,
numerology, BWP, F1 path, UPF, and transport settings were unchanged during
this intervention. The final 99.8 Mb/s mean therefore belongs to the
BLER-retuned configuration under the recorded RF condition; it is not a
universal BLER optimum.

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
