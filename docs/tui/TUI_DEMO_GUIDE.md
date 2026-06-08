# TUI Demo Guide

## Launch

From the canonical repository:

```bash
./scripts/oai-lab-tui
```

For non-interactive checks:

```bash
./scripts/oai-lab-tui --verify
```

## Recommended Live Sequence

1. Start Ethernet CU/DU rollback baseline.
2. Apply a short PWS message, restart the selected scenario, and record the
   phone observation.
3. Record guided phone throughput for the split baseline.
4. Stop the split scenario cleanly.
5. If time allows, run monolithic startup on `serber-firecell` and record the
   reference throughput.

Do not present `serber-pi`, `oai-pc`, or nrUE internet-through-radio as working
until their preflight and launch evidence is recorded.

If the professor asks why `oai-pc` is mentioned during Ethernet startup: a stale
`oai-pc` DU was observed trying to connect to the CU with the same DU identity.
The TUI isolates that peer only for the minipc rollback demo and removes the
temporary block when the split scenario is stopped.

Ethernet startup also stops the firecell monolithic core containers first. The
split demo should not have both the monolithic `oai-*` core and the
`oai-cn5g-minipc-*` split core running at the same time.

For phone internet, confirm the Nothing Phone APN/DNN is `oai` before toggling
airplane mode. If the SMF reports DNN/subscription errors, the phone may attach
at RRC/NAS level but still have no usable data.
