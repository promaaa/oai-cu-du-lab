# Caged Quectel Access F1-U Recovery

Date: 2026-06-12

Result: **PASS.** The run recovered the previously missing access-cell user-plane evidence: the Nothing Phone moved to the minipc access DU, bidirectional F1-U `UDP/2153` was observed on `wg-quectel-f1`, and the operator confirmed Fast.com internet throughput on the Nothing Phone.

## Changes Applied

- Set minipc CPU governors to `performance` before access DU launch.
- Redacted TUI evidence writes at the shared evidence writer.
- Increased default firecell donor TX attenuation from `18` to `24` so the caged phone prefers access PCI `0`/TAC `1` while the Quectel remains on donor PCI `1`/TAC `2`.
- Updated standalone minipc WireGuard setup to write the `PreUp` route from live QMI IP/gateway values, preventing stale `src` routes after the Quectel PDU address changes.

## Sanitized Evidence

- Quectel donor registration after attenuation change:
  - donor PCI `1`, TAC `2`, SSB `641280`, band `n78`;
  - serving-cell RSRP about `-97 dBm`;
  - QMI PDU connected at `10.0.0.3/29` via `10.0.0.4`.
- WireGuard over Quectel:
  - `10.250.0.2 -> 10.250.0.1` ping passed with `0%` loss;
  - `10.250.0.1 -> 10.250.0.2` ping passed with `0%` loss;
  - outer WireGuard UDP was visible on `wwan0` between `10.0.0.3` and `192.168.71.129`.
- Access CU/DU:
  - CU accepted DU `3585`;
  - access cell PLMN `001/01`, Cell ID `12345678`, PCI `0`, TAC `1` was in service;
  - CU sent SIB8/PWS after F1 setup.
- Access UE/user-plane:
  - access DU showed UE RNTI `dbd2` in sync with average RSRP around `-82` to `-86`;
  - access DU showed low BLER and sustained SRB activity;
  - minipc and firecell captures both showed bidirectional F1-U `UDP/2153` over `wg-quectel-f1`;
  - representative F1-U packet sizes included uplink and downlink packets larger than 1200 bytes.
- Operator phone observation:
  - Nothing Phone internet worked through the access DU path;
  - Fast.com measured about `5.5 Mb/s`.
- Isolation:
  - short Ethernet/Wi-Fi management captures on minipc and firecell showed no F1-C SCTP or F1-U `UDP/2153`;
  - WireGuard outer UDP was visible on the Quectel data interface.

## Throughput Follow-Up

The `5.5 Mb/s` Fast.com result is below the prior Ethernet split baseline of about `19-23 Mb/s`. The next optimization pass should preserve the working packet gates while investigating split scheduler/MCS behavior, Quectel donor quality, WireGuard overhead, and access RF feedback.

## Rollback

Use:

```bash
./scripts/oai-lab-tui --rollback-caged-quectel
```

The Ethernet CU/DU with SIB8 remains the rollback baseline.
