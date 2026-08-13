# Sanitized benchmark ledger

Last reconciled: 2026-08-13.

The project campaign repeatedly exercised deployment, F1 path, PWS,
registration, data, throughput, stop, and rollback gates. The values below are
the best-observed end-to-end downlink outcomes retained from those trials.
They are not fixed-condition statistical means and must not be used as a
controlled ranking of hosts or F1 bearers.

| Record ID | DU | F1 bearer | DL result | Interpretation |
|---|---|---|---:|---|
| `X86-MONO-190` | x86 | local/monolithic | 190 Mb/s | reference snapshot |
| `X86-ETH-100` | x86 | Ethernet | 100 Mb/s peak; 89 Mb/s sustained | BLER retuning and MCS recovery |
| `X86-GRE-52` | x86 | Wi-Fi/GRE | 52 Mb/s | wireless F1 snapshot |
| `X86-QWG-78` | x86 | 5G/WireGuard | 78 Mb/s | final x86 cellular-backhaul snapshot |
| `PI-ETH-21` | Raspberry Pi 5 | Ethernet | 21 Mb/s | Arm feasibility snapshot |
| `PI-GRE-13` | Raspberry Pi 5 | Wi-Fi/GRE | 13 Mb/s | Arm feasibility snapshot |
| `PI-QWG-48` | Raspberry Pi 5 | 5G/WireGuard | 48 Mb/s | Arm feasibility snapshot |
| `JETSON-ETH-7.3` | Jetson Orin Nano | Ethernet | 7.3 Mb/s | earlier USB/BLER-limited state |
| `JETSON-QWG-INT-44` | Jetson Orin Nano | 5G/WireGuard | about 40-44 Mb/s | intermediate accepted configuration |
| `JETSON-QWG-FINAL-68` | Jetson Orin Nano | 5G/WireGuard | 68 Mb/s | final clean launch and corrected runtime/scheduler state |

## Jetson chronology

The 68 Mb/s value does not describe the same software/runtime state as the
earlier 40-44 Mb/s result. The intermediate record is retained rather than
silently overwritten. The final run used the full MCS range and the validated
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
89 Mb/s sustained and approximately 100 Mb/s peak rates are retained as the
outcome of the complete validated configuration, not as a universal target or
an isolated scheduler-effect estimate.

## Acceptance gates

Every retained cellular result passed the selected access-cell check, PWS,
registration, PDU-session, Internet, timestamped handset measurement, clean
stop, and rollback gates. Interface captures separately established F1-C,
F1-U, and the encrypted outer WireGuard path. Raw captures and logs remain
outside Git; only this sanitized ledger is public.
