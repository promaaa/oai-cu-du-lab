# OAI CU/DU Lab

Canonical control repository for an OpenAirInterface 5G NR CU/DU split lab
with SIB8/PWS and Ethernet, Wi-Fi GRE, and Quectel/WireGuard F1 transports.

## Current state

- Ethernet CU/DU with SIB8 is the rollback baseline.
- The monolithic deployment is a reference, not the target architecture.
- The target Quectel design is one shared CU with an independent donor DU and
  an access DU. The older monolithic-donor flow is not proof of that design.
- No scenario is a full PASS without separate phone-visible PWS, registration,
  PDU session, internet, and throughput evidence.

See [Current status](docs/STATUS.md) before operating the lab.

## Quick start

```bash
./scripts/oai-lab-tui
```

The TUI writes runtime evidence outside the repository under
`~/.local/state/oai-cu-du-lab/runs/`. Override this with
`OAI_LAB_STATE_DIR` when another private evidence location is required.

## Repository map

- `conf/` — sanitized templates; local and generated configuration is ignored.
- `docs/` — the canonical architecture, status, operating, and security guides.
- `patches/` — feature-separated changes for the pinned external OAI source.
- `scripts/` — the operator TUI, focused helpers, and static tests.
- `wiki/` — the small public operator reference published by GitHub Pages.

OAI source, generated configs, credentials, raw logs, and packet captures stay
outside Git.

## Read next

- [Architecture](docs/ARCHITECTURE.md)
- [Baselines](docs/BASELINES.md)
- [Network and hardware](docs/NETWORK.md)
- [Operator guide](docs/OPERATOR_GUIDE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Security](docs/SECURITY.md)
