# Baselines

## Monolithic OAI Reference

- Status: working gated TUI reference.
- Observed user throughput: about `150 Mb/s`.
- Role: separate reference only. It is not the Quectel F1 backhaul architecture.
- OAI commit: not confirmed from repository evidence for this exact baseline.

## Ethernet CU/DU With SIB8

- Status: working canonical rollback baseline.
- Observed user throughput: about `19-23 Mb/s`.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37`.
- Rollback baseline: yes.

## Wi-Fi CU/DU With SIB8

- Status: working wireless-backhaul baseline candidate.
- Observed user throughput: about `12 Mb/s`.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37`.
- Rollback baseline: no, but documented as confirmed working.

## Quectel F1 Backhaul

- Status: target architecture documented; runtime implementation and PASS require fresh live packet-gated validation.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37`.
- Rollback baseline: no; rollback target is Ethernet CU/DU.
- Canonical architecture: one 5GC and one shared CU on `serber-firecell`; one donor DU for the Quectel serving cell; one access DU on `serber-minipc`; access-DU F1 over WireGuard-over-Quectel.
- Donor rule: Quectel attaches only to the independent donor-DU cell; it must never attach to the minipc access DU.
- Access rule: B210 serial `8002816` remains access-cell only, PCI `0`, TAC `1`, DU ID `0xe01`.
- PASS rule: no PASS without both donor-DU and access-DU F1 evidence, Quectel serving-cell/IP evidence, tcpdump proof for minipc F1-C/F1-U on `wg-quectel-f1`, WireGuard outer UDP on `wwan0`, phone service/PWS evidence, and a verified Ethernet rollback.
