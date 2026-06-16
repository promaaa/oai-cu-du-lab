# Scripts

## Operator TUI

Run from the repository root:

```bash
./scripts/oai-lab-tui
```

Useful non-interactive checks:

```bash
./scripts/oai-lab-tui --verify
```

Read-only split performance evidence window:

```bash
./scripts/collect-split-performance-window.sh 60
```

Run it only after intentionally starting the scenario to measure. It creates an
ignored local directory under `experiments/20*/` with process state, host
counters, SCTP summaries, ping timing, and filtered logs. It does not start or
stop OAI processes and does not collect raw packet captures.

On interactive startup, the launcher first shows the active config and asks
whether to use it. Operators can keep the current environment/default values,
choose the default `serber-firecell` + `serber-minipc` layout, choose the
default `serber-firecell` + `serber-pi` layout, or enter custom firecell/Pi IP
addresses.

Default professor-demo targets:

- `serber-firecell`: `serber@10.76.170.38`
- `serber-minipc`: `serber@10.76.170.100`
- `serber-pi`: `serber-pi`

Monolithic reference startup runs on `serber-firecell`, matching the existing
monolithic demo workflow. Ethernet rollback startup runs Core/CU on
`serber-firecell`, DU/radio on the selected DU, stops the firecell monolithic
core first, and temporarily blocks the stale `oai-pc` F1 peer (`10.76.170.90`).
Quectel launch/validation remains guarded to the validated minipc modem path.

Keep it free of passwords, subscriber values, generated configs, raw logs, and
private keys. Runtime evidence stays in ignored `experiments/20*/` directories.
