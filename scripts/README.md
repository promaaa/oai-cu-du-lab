# Scripts

## Operator interface

```bash
./oai-lab
./oai-lab --help
./oai-lab --check-local-setup
```

`./oai-lab` is the only supported operator entry point. It selects the DU and
F1 transport, performs fail-closed preflight, starts and stops supported
scenarios, and records private runtime evidence. Files under `scripts/lib/`
are internal implementation details and must not be launched directly.

`--check-local-setup` checks only the local operator workstation and private
environment file. `--verify` contacts the configured lab hosts.

The TUI records its run output outside the repository at:

```text
~/.local/state/oai-cu-du-lab/runs/
```

Set `OAI_LAB_STATE_DIR` to select another private location. Do not copy raw
logs, captures, generated configs, credentials, or subscriber data into Git.
