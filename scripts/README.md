# Scripts

## Operator interface

```bash
./oai-lab
./oai-lab --help
./oai-lab --doctor
```

The TUI selects the DU and F1 transport, performs fail-closed preflight,
starts and stops supported scenarios, and records private runtime evidence.
`--doctor` checks only the local Mac and private environment file. `--verify`
contacts the configured lab hosts.

Run the dependency-free static suite without contacting the lab:

```bash
node scripts/tests/oai-lab-tui-static.test.mjs
```

Static tests prove CLI/menu dispatch and external-command blocking only. They
are not radio or phone evidence.

## Evidence collection

```bash
./scripts/collect-split-performance-window.sh 60
./scripts/collect-software-power-profile.sh 60
```

All run output is stored outside the repository at:

```text
~/.local/state/oai-cu-du-lab/runs/
```

Set `OAI_LAB_STATE_DIR` to select another private location. Do not copy raw
logs, captures, generated configs, credentials, or subscriber data into Git.

## Quectel helpers

The scripts under `quectel-f1-backhaul/` remain diagnostic building blocks.
The current monolithic-donor path is legacy and cannot prove the canonical
one-CU/two-DU target. See `docs/QUECTEL_BACKHAUL.md`.
