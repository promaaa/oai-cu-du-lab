# Current status

Last reconciled: 2026-08-13.

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
trials. The values in the benchmark matrix are the arithmetic mean throughput
for each setup. The reconciled chronology, including the earlier 40-44 Mb/s
Jetson state and the final 68 Mb/s Jetson mean, is published in
`docs/evidence/BENCHMARKS.md`. The per-run series and dispersion were not
retained in the public artifact, so the means have no invented error bars and
must not be treated as a matched-condition ranking of transports.

Sanitized Raspberry Pi CPU, memory, temperature, and stability observations
are published in `docs/evidence/RESOURCE_PROFILE.md`. Full-payload electrical
power remains an engineering estimate rather than a synchronized measurement.

Continue recording machine-side and phone-side gates separately for every new
run. Physical B210 ownership and exclusive lab ownership must still be checked
before launch.
