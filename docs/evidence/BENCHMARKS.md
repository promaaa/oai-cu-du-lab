# Sanitized benchmark ledger

Last reconciled: 2026-08-13.

The project campaign repeatedly exercised deployment, F1 path, PWS,
registration, data, throughput, stop, and rollback gates. Each final setup
below has 20 accepted repetitions, and its displayed downlink value is the
arithmetic mean confirmed by the authors. The per-run series and dispersion
were not retained in the public artifact; no individual observations or error
bars are reconstructed. Cross-setup conditions evolved, so the means must not
be used as a controlled ranking of hosts or F1 bearers.

| Record ID | DU | F1 bearer | DL mean, n=20 | Interpretation |
|---|---|---|---:|---|
| `X86-MONO-190` | x86 | local/monolithic | 190 Mb/s | monolithic reference |
| `X86-ETH-100` | x86 | Ethernet | 100 Mb/s | BLER retuning and MCS recovery |
| `X86-GRE-52` | x86 | Wi-Fi/GRE | 52 Mb/s | wireless F1 setup |
| `X86-QWG-78` | x86 | 5G/WireGuard | 78 Mb/s | final x86 cellular-backhaul setup |
| `PI-ETH-21` | Raspberry Pi 5 | Ethernet | 21 Mb/s | Arm feasibility setup |
| `PI-GRE-13` | Raspberry Pi 5 | Wi-Fi/GRE | 13 Mb/s | Arm feasibility setup |
| `PI-QWG-48` | Raspberry Pi 5 | 5G/WireGuard | 48 Mb/s | Arm feasibility setup |
| `JETSON-ETH-7.3` | Jetson Orin Nano | Ethernet | 7.3 Mb/s | USB/BLER-limited setup |
| `JETSON-QWG-FINAL-68` | Jetson Orin Nano | 5G/WireGuard | 68 Mb/s | corrected runtime/scheduler setup |

## Jetson chronology

The 68 Mb/s mean does not describe the same software/runtime state as the
earlier 40-44 Mb/s chronology. The intermediate record is retained rather than
silently overwritten or folded into the final mean. The final setup used the
full MCS range and the validated
Jetson runtime profile: maximum-performance mode, locked clocks, USB
autosuspend disabled, `usbfs_memory_mb=1000`, B210 at `5000M`, DU affinity on
CPUs 1-5, and the active xHCI interrupt on CPU 0. The research paper reports
the final value and explicitly identifies the earlier range.

## BLER-dominant mechanism

`X86-ETH-100` includes direct scheduler evidence: filtered BLER stayed outside
the default target, the controller repeatedly reduced MCS, and MCS remained at
its configured floor. This makes the BLER-controller mismatch the dominant
observed limiter. The DL target window changed from 0.05--0.15 to 0.25--0.35;
the dominant MCS moved from 5 to 24--27 in the instrumented after window. The
final setup averaged 100 Mb/s across 20 repetitions. This is the outcome of the
complete validated configuration, not a universal target or an isolated
scheduler-effect estimate.

The manuscript plot is sourced from `docs/evidence/throughput-means.csv`.

## Acceptance gates

Every retained cellular result passed the selected access-cell check, PWS,
registration, PDU-session, Internet, timestamped handset measurement, clean
stop, and rollback gates. Interface captures separately established F1-C,
F1-U, and the encrypted outer WireGuard path. Raw captures and logs remain
outside Git; only this sanitized ledger is public.
