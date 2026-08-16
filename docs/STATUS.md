# Current status

Last reconciled: 2026-08-14.

All supported TUI configurations have working lab evidence.

| Access DU | Ethernet F1 | Wi-Fi GRE F1 | Quectel/WireGuard F1 |
|---|---|---|---|
| MiniPC | `WORKING` | `WORKING` | `WORKING` |
| Raspberry Pi | `WORKING` | `WORKING` | `WORKING` |
| Jetson | `WORKING` | `WORKING` | `WORKING` |

The monolithic reference, SIB8/PWS delivery over F1, phone registration, PDU
session, internet connectivity, throughput validation, clean stop, and MiniPC
Ethernet rollback are also working. The PWS code-to-execution mapping is
published in `docs/evidence/PWS-F1.md`.

The supported final scenarios were each exercised in 20 accepted end-to-end
trials in the same enclosed laboratory RF environment. The access-cell radio
profile, intended handset, pinned OAI revision, and validation workflow were
held fixed; the DU host, selected F1 bearer, host-specific runtime profile, and
named scheduler/transport interventions distinguish the configurations. The
200 per-run downlink observations are now retained in
`docs/evidence/throughput-observations.csv`; the arithmetic means, sample
standard deviations, ranges, and 95% confidence intervals derived from them
are in `docs/evidence/throughput-means.csv`. The current statistical record is
published in `docs/evidence/BENCHMARKS.md`. The controlled lab reduces
environmental variation, but the configurations must not be treated as a
one-factor ranking because host, bearer, runtime, and BLER state differ.

Sanitized Raspberry Pi CPU, memory, temperature, and stability observations
are published in `docs/evidence/RESOURCE_PROFILE.md`. Full-payload electrical
power remains an engineering estimate rather than a synchronized measurement.

Continue recording machine-side and phone-side gates separately for every new
run. Physical B210 ownership and exclusive lab ownership must still be checked
before launch.
