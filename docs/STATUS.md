# Current status

Last reconciled: 2026-07-29.

All supported TUI configurations have working lab evidence.

| Access DU | Ethernet F1 | Wi-Fi GRE F1 | Quectel/WireGuard F1 |
|---|---|---|---|
| MiniPC | `WORKING` | `WORKING` | `WORKING` |
| Raspberry Pi | `WORKING` | `WORKING` | `WORKING` |
| Jetson | `WORKING` | `WORKING` | `WORKING` |

The firecell monolithic reference, SIB8/PWS delivery, phone registration, PDU
session, internet connectivity, throughput validation, clean stop, and MiniPC
Ethernet rollback are also working.

This capability matrix does not replace the freshness classification in
`BASELINES.md`. A capability can remain `WORKING` while a new controlled rerun
is `BLOCKED`, `PARTIAL`, or still required.

Continue recording machine-side and phone-side gates separately for every new
run. Physical B210 ownership and exclusive lab ownership must still be checked
before launch.
