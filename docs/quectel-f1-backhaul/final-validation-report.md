# Final Validation Report — Quectel F1 Backhaul

**Status**: template for the single-CU firecell donor DU target. Do not mark
PASS until the packet gate in `08_validate_f1.sh` passes during live phone
traffic.

## Target Architecture

| Component | Expected state |
|---|---|
| 5GC | one OAI 5GC on `serber-firecell` |
| CU | one OAI CU on `serber-firecell` |
| Donor DU | firecell donor DU on `serber-firecell`, PCI `1`, TAC `2`, DU ID `0xe11` |
| Donor F1 | local firecell path only, `127.0.0.2` -> `127.0.0.1` |
| Quectel | RM500Q-GL outside cage attached only to firecell donor DU |
| Access DU | minipc access DU on `serber-minipc`, PCI `0`, TAC `1`, DU ID `0xe01` |
| Access radio | B210 serial `8002816`, access-cell only |
| Access F1 | `10.250.0.2` -> CU `10.250.0.1` over `wg-quectel-f1` |
| WireGuard outer path | UDP over Quectel `wwan0` |

No monolithic donor gNB is valid for this report.

## PASS Checklist

- [ ] firecell donor DU has F1 setup to the shared CU on local path;
- [ ] Quectel modem is registered on donor PCI `1` / TAC `2`;
- [ ] Quectel `wwan0` has an IPv4 PDU session;
- [ ] `wg-quectel-f1` has a fresh handshake and bidirectional ping;
- [ ] minipc access DU has F1 setup to the shared CU over `wg-quectel-f1`;
- [ ] tcpdump proves minipc F1-C SCTP on `wg-quectel-f1`;
- [ ] tcpdump proves minipc F1-U UDP/2153 on `wg-quectel-f1` during phone traffic;
- [ ] tcpdump proves WireGuard outer UDP on `wwan0`;
- [ ] tcpdump proves management Ethernet/WiFi do not carry minipc F1;
- [ ] Nothing Phone inside the cage is served by the minipc access DU.

## Runtime Evidence

Fill this section only from a live run:

| Check | Result |
|---|---|
| Core health | `<PASS/FAIL>` |
| CU process/config | `<path and PID>` |
| Donor DU process/config | `<path and PID>` |
| Access DU process/config | `<path and PID>` |
| Quectel serving cell | `<PCI/TAC/PLMN>` |
| Quectel PDU IP/gateway | `<IP/gateway>` |
| WireGuard handshake | `<latest handshake>` |
| Donor local F1 capture | `<PASS/FAIL>` |
| Access F1-C capture | `<PASS/FAIL>` |
| Access F1-U capture | `<PASS/FAIL>` |
| WireGuard outer capture | `<PASS/FAIL>` |
| Management no-F1 captures | `<PASS/FAIL>` |
| Phone attach/access cell | `<PASS/FAIL>` |
| Throughput | `<measured>` |

## Rollback

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```
