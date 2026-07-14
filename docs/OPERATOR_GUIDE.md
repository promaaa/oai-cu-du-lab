# Operator guide

## Before touching the lab

Read `STATUS.md`, obtain sole ownership of the shared lab, and discover the
physical B210 location. Do not infer ownership from old configuration.

## Start the TUI

```bash
./scripts/oai-lab-tui
```

Useful local checks:

```bash
./scripts/oai-lab-tui --help
node scripts/tests/oai-lab-tui-static.test.mjs
```

`--verify` contacts configured hosts; the static test does not.

## Runtime evidence

Run records are private local state, not repository content:

```text
~/.local/state/oai-cu-du-lab/runs/<timestamp>_<scenario>/
```

Set `OAI_LAB_STATE_DIR=/private/path` to use another location. Review and
sanitize evidence before copying a minimal conclusion into `STATUS.md` or
`BASELINES.md`. Never commit raw logs or captures.

## Standard validation order

1. Record repository and external OAI commits.
2. Record host, radio, transport, and active process ownership.
3. Confirm the Ethernet rollback can be restored.
4. Start core, CU, DU, radio, and selected transport through the TUI.
5. Verify machine gates without labeling them a scenario PASS.
6. Record phone PWS, registration, PDU, internet, and throughput separately.
7. Stop through the TUI and check process, route, firewall, MTU, and tunnel
   residue.
8. Update canonical status with only sanitized conclusions.

## Focused collection

```bash
./scripts/collect-split-performance-window.sh 60
./scripts/collect-software-power-profile.sh 60
```

Power telemetry is planning evidence only until the complete payload is
measured at its DC input.
