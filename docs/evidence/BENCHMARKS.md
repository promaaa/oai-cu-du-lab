# Sanitized benchmark ledger

Last reconciled: 2026-08-14.

The project campaign repeatedly exercised deployment, F1 path, PWS,
registration, data, throughput, stop, and rollback gates. Each final setup
below has 20 accepted repetitions. The same enclosed laboratory RF
environment, access-cell radio profile, intended handset, pinned OAI revision,
and validation workflow were used throughout. The DU host and selected F1
bearer are deliberate configuration variables; host-specific runtime settings
and the named BLER intervention also distinguishes recorded setups.

The 200 per-run downlink observations are retained in
`docs/evidence/throughput-observations.csv`. The summary below is recomputed
from those values: sample standard deviation uses the $n-1$ denominator and
the two-sided 95% confidence interval (CI) for the mean uses Student's
$t_{0.975,19}=2.093$. These results establish end-to-end feasibility under the
recorded configurations, not a one-factor ranking of hosts or bearers.
The public CSV orders each configuration's values from lowest to highest;
`observation_rank` is therefore a within-series rank, not acquisition time or
a trial identifier shared across configurations.

| Record ID | DU | F1 bearer | DL mean +/- SD, n=20 | 95% CI (Mb/s) | Interpretation |
|---|---|---|---:|---:|---|
| `X86-MONO-FINAL` | x86 | local/monolithic | 190.675 +/- 1.420 Mb/s | 190.010--191.340 | monolithic reference |
| `X86-ETH-FINAL` | x86 | Ethernet | 99.770 +/- 2.513 Mb/s | 98.594--100.946 | BLER-retuned final setup |
| `X86-GRE-FINAL` | x86 | Wi-Fi/GRE | 52.010 +/- 0.888 Mb/s | 51.594--52.426 | wireless F1 setup |
| `X86-QWG-FINAL` | x86 | 5G/WireGuard | 76.690 +/- 4.508 Mb/s | 74.580--78.800 | final x86 cellular-backhaul setup |
| `PI-ETH-FINAL` | Raspberry Pi 5 | Ethernet | 21.855 +/- 3.354 Mb/s | 20.285--23.425 | Arm feasibility setup |
| `PI-GRE-FINAL` | Raspberry Pi 5 | Wi-Fi/GRE | 12.730 +/- 2.923 Mb/s | 11.362--14.098 | Arm feasibility setup |
| `PI-QWG-FINAL` | Raspberry Pi 5 | 5G/WireGuard | 47.795 +/- 0.704 Mb/s | 47.465--48.125 | Arm feasibility setup |
| `JETSON-ETH-FINAL` | Jetson Orin Nano | Ethernet | 10.185 +/- 1.202 Mb/s | 9.623--10.747 | USB/BLER-limited setup |
| `JETSON-GRE-FINAL` | Jetson Orin Nano | Wi-Fi/GRE | 8.105 +/- 0.513 Mb/s | 7.865--8.345 | USB/BLER-limited setup |
| `JETSON-QWG-FINAL` | Jetson Orin Nano | 5G/WireGuard | 68.435 +/- 1.504 Mb/s | 67.731--69.139 | corrected runtime/scheduler setup |

## Jetson final configuration

The 68.4 Mb/s mean uses the full MCS range and the validated Jetson runtime
profile: maximum-performance mode, locked clocks, USB
autosuspend disabled, `usbfs_memory_mb=1000`, B210 at `5000M`, DU affinity on
CPUs 1-5, and the active xHCI interrupt on CPU 0.

## BLER-dominant mechanism and causal boundary

`X86-ETH-FINAL` includes direct scheduler evidence: filtered BLER stayed outside
the default target, the controller repeatedly reduced MCS, and MCS remained at
its configured floor. This makes the BLER-controller mismatch the dominant
observed limiter. The DL target window changed from 0.05--0.15 to 0.25--0.35;
the dominant MCS moved from 5 to 24--27 in the instrumented after window. The
radio profile, attenuation, numerology, BWP, F1 path, UPF, and transport
settings were unchanged during the intervention. The trace directly supports
the observed controller mechanism, while the 99.8 Mb/s mean characterizes the
complete BLER-retuned configuration under the recorded RF condition rather
than a universal target-window optimum.

The manuscript plot is sourced from `docs/evidence/throughput-means.csv`,
which is derived from `docs/evidence/throughput-observations.csv`.

## Acceptance gates

Every retained cellular result passed the selected access-cell check, PWS,
registration, PDU-session, Internet, timestamped handset measurement, clean
stop, and rollback gates. Interface captures separately established F1-C,
F1-U, and the encrypted outer WireGuard path. Raw captures and logs remain
outside Git; only this sanitized ledger is public.
