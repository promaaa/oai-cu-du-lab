# Current status

Last reconciled: 2026-07-14.

This is the sole concise status page. `PASS` means every applicable machine and
phone gate in `BASELINES.md` has fresh evidence.

## Acceptance snapshot

| Scenario | Status | Proven | Remaining blocker |
|---|---|---|---|
| Firecell monolithic reference | `PARTIAL` | core, NG, RF, timing, SIB8 build path, isolation | no fresh phone PWS, registration, PDU, internet, or throughput |
| MiniPC Ethernet rollback | `BLOCKED` | fail-closed preflight | B210 `8002816` was on Jetson, not MiniPC; exclusive ownership was lost |
| Jetson Ethernet split | `PARTIAL` | USB3, F1-C/F1-U startup, RF sync, network-side PWS, registration, PDU, stable external-DN ping after IRQ fix | user reported PWS but no 5G service or internet; phone throughput absent |
| Pi and Wi-Fi paths | `HISTORICAL` | earlier working evidence | no fresh end-to-end rerun |
| Quectel target | `BLOCKED` | legacy modem/WireGuard and packet-path work | one shared CU with donor DU and access DU has not been proven |
| X310 106 PRB | `BLOCKED` | transport failure reproduced | available path negotiated 1 Gb/s and overflowed |

## Latest Jetson finding

The replacement USB cable allows B210 `8002816` to re-enumerate at `5000M`
and operate over USB3. It did not remove the user-plane blocker by itself.
Pinning the active `xhci-hcd` interrupt to CPU 0 changed external-DN loss from
76.7% to 0% in two follow-up ping windows and stopped the overflow count from
increasing during those checks. The TUI now selects the active xHCI interrupt.

This remains `PARTIAL`: the user subsequently observed PWS but no 5G service or
internet. The next run must refresh attach and PDU state rather than assuming
the earlier bearer remains active.

## Next safe sequence

1. Establish one live-lab owner and inventory all running cores, CU/DU
   processes, routes, tunnels, radios, modem state, and phone availability.
2. Restore B210 `8002816` to MiniPC on a true `5000M` path and prove UHD use.
3. Reconcile CU and DU source commits and required SIB8 patches.
4. Rerun MiniPC Ethernet and record every machine and phone gate separately.
5. Only after rollback acceptance, continue Pi, Jetson, Wi-Fi, Quectel, or X310
   validation.
