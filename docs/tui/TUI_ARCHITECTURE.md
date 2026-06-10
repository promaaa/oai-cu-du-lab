# TUI Architecture

The operator console is implemented as one dependency-free Node script:

```bash
./scripts/oai-lab-tui
```

It follows the working `5g-tui` style: boxed headers, numbered prompts,
step-by-step launch output, and direct SSH commands. It is hard-coded for the
current professor-demo lab rather than a broad deployment framework.

## Safety Model

- Starts are explicit menu actions.
- Ethernet/monolithic starts stop the selected scenario's existing
  `nr-softmodem` processes before relaunch.
- Discovery actions are read-only.
- Unverified scenarios expose discovery/preflight only, not success-oriented
  launch actions.
- Stop actions target known OAI process names and known logs only.
- Raw run evidence is stored in ignored timestamped directories under
  `experiments/20*/`.
- Secrets and subscriber values are not accepted as configuration fields.

## Run Records

Actions that capture evidence create a run directory:

```text
experiments/YYYYMMDD_HHMMSS_<scenario>/
  notes.md
  logs/
  measurements/
  system-status/
```

These directories are intentionally ignored by Git until evidence is sanitized
and manually summarized.
