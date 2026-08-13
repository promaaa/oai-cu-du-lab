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

The reconciled throughput chronology, including the intermediate 40-44 Mb/s
and final 68 Mb/s Jetson records, is published in
`docs/evidence/BENCHMARKS.md`. These are best-observed snapshots, not
fixed-condition repeated-run means.

Continue recording machine-side and phone-side gates separately for every new
run. Physical B210 ownership and exclusive lab ownership must still be checked
before launch.
