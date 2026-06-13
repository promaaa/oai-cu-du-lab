# Caged Quectel Phone Source Validation

Date: 2026-06-13

Result: **No PASS claimed for the current 50 Mb/s phone result.** The live validation did not prove that the Nothing Phone throughput was served by the `serber-minipc` access DU.

## Why This Was Checked

The operator observed about `50 Mb/s` on Fast.com, which is higher than the prior caged Quectel result and closer to a non-split or donor-side path than expected. The validation goal was to remove ambiguity between:

- phone attached to the minipc access DU, PCI `0`, TAC `1`, with user plane carried as F1-U over `wg-quectel-f1`; and
- phone attached to the firecell monolithic donor or another non-minipc path.

## Live Findings

- `serber-firecell` showed the split core and CU process for the Quectel config.
- The controller initially did not see the firecell monolithic donor gNB process in the live process list.
- `serber-minipc` was reachable through the KAUST host alias path and reported:
  - Quectel data interface `wwan0`;
  - live PDU `10.0.0.2/30` via `10.0.0.1`;
  - `wg-quectel-f1` address `10.250.0.2/30`.
- WireGuard validation failed:
  - minipc sent WireGuard bytes but received `0 B`;
  - minipc ping to `10.250.0.1` had `100%` packet loss;
  - firecell ping to `10.250.0.2` had `100%` packet loss.
- Gates reached only:
  - Quectel PDU discovery;
  - route refresh.
- The validation stopped before any phone-source or F1-U PASS gate.

## TUI Hardening Added

The caged Quectel validation now requires stronger source proof:

- running process/config identity for:
  - firecell CU config;
  - firecell donor gNB config;
  - minipc access DU config;
- minipc access DU config identity:
  - PCI `0`;
  - TAC `1`;
  - Cell ID `12345678`;
  - B210 serial `8002816`;
  - F1 addresses `10.250.0.2` to `10.250.0.1`;
- phone traffic must produce `UDP/2153` on **minipc** `wg-quectel-f1`;
- firecell-only tunnel evidence is no longer enough to attribute throughput to the minipc access DU;
- each phone traffic attempt writes a source-proof marker and stores fresh post-marker CU/DU/donor excerpts.

## Interpretation

The observed `50 Mb/s` should not be recorded as minipc-access throughput unless a new validation run passes the source-proof gate while the Fast.com test is running. With the current failed WireGuard state, the result is more likely from a different radio/source path than the intended caged Quectel F1 backhaul.

## Next Action

Restore the full caged Quectel launch, then run:

```bash
./scripts/oai-lab-tui --validate-caged-quectel
```

During step 7, start the Fast.com test on the Nothing Phone. Only treat the result as minipc-access throughput if the TUI captures F1-U `UDP/2153` on the minipc `wg-quectel-f1` interface during that same window.
