# Caged Quectel Access F1-U Recovery

Date: 2026-06-12

Result: **No full PASS claimed without operator-visible internet or throughput confirmation.** The run recovered the previously missing access-cell user-plane evidence: the Nothing Phone moved to the minipc access DU, and bidirectional F1-U `UDP/2153` was observed on `wg-quectel-f1`.

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
- Isolation:
  - short Ethernet/Wi-Fi management captures on minipc and firecell showed no F1-C SCTP or F1-U `UDP/2153`;
  - WireGuard outer UDP was visible on the Quectel data interface.

## Remaining Gate

Record one explicit operator observation of Nothing Phone internet or a throughput result before marking the whole scenario full PASS.

## Rollback

Use:

```bash
./scripts/oai-lab-tui --rollback-caged-quectel
```

The Ethernet CU/DU with SIB8 remains the rollback baseline.
