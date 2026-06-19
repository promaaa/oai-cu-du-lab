# Single-B210 RF Backhaul Experiment Plan

Date: 2026-06-18

## Goal

Evaluate whether the `serber-minipc` USRP B210 can replace the Quectel modem
for the experimental drone-oriented backhaul while still serving the Nothing
Phone access cell.

Requested temporary topology:

- Quectel suppressed and not used for F1.
- One B210 on `serber-minipc`, serial `8002816`.
- One RF pair reserved for the backhaul direction.
- One RF pair reserved for the Nothing Phone access cell.
- Ethernet CU/DU with SIB8 preserved as rollback.

## Current Guardrail

The B210 exposes two TX and two RX RF chains on one UHD device. That is enough
for 2x2 MIMO experiments, but it is not by itself proof that OAI can run a
separate RF-backhaul endpoint and access DU simultaneously on the same B210.
The TUI experimental mode therefore fails closed until this dual-role OAI
architecture is proven with logs and packet evidence.

## TUI Entry Point

```bash
./scripts/oai-lab-tui --experimental-b210
```

The same action is available from the main TUI as:

```text
Experimental mode: suppress Quectel and probe single-B210 RF backhaul
```

## Evidence Gates

The temporary mode records:

- live `serber-minipc` discovery;
- rollback context;
- Quectel/WireGuard suppression state;
- B210/UHD probe output;
- DU OAI commit when readable;
- a `/tmp` experimental runtime marker;
- packet checks showing no F1 on `wg-quectel-f1` or `wwan0`;
- an explicit architecture gate explaining whether the requested dual-role RF
  setup is proven.

## Rollback

Use the existing TUI stop action, then launch the Ethernet CU/DU rollback:

```bash
./scripts/oai-lab-tui --rollback-caged-quectel
./scripts/oai-lab-tui --start-ethernet
```

Do not remove or overwrite the Quectel scripts, generated Quectel configs, or
Ethernet rollback configs while this experiment is unresolved.

## Next Actions

1. Confirm live minipc SSH reachability and B210 probe output.
2. Identify the smallest OAI-supported way to instantiate independent
   backhaul and access roles without unsafe shared UHD ownership.
3. If source changes are needed, store them as a feature-separated patch under
   `patches/`.
4. Validate with sanitized logs, packet evidence, UE state, and rollback
   comparison before marking the experiment as working.
