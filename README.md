# oai-cu-du-lab

Private canonical control repo for an OAI 5G NR CU/DU split research lab.

## Objective

Investigate an OAI CU/DU split that can broadcast SIB8/PWS messages and later carry F1 over a wireless backhaul suitable for a lightweight or drone-carried DU.

## Current Status

This repo now contains the lean lab context plus an operator TUI that can launch the deployed baselines from one place. OAI source trees, generated runtime configs, logs, captures, and credentials remain outside Git.

## Repository Purpose

This repository gives future operators and agents a clean starting point for deployment-oriented work without requiring them to rediscover old public repositories.

## Directory Overview

- `docs/`: concise system, baseline, security, roadmap, and runbook context.
- `inventory/`: compact machine-readable host, radio, and baseline inventory.
- `experiments/`: future experiment index and report template.
- `prompts/`: reusable prompt skeletons for future agents.
- `patches/`: feature-separated patches and concise migration notes.
- `conf/`: sanitized templates and generated-config placeholders.
- `scripts/`: the launch TUI and vetted reusable helpers.
- `audit/`: source repository audit, exposure report, and migration map.
- `wiki/`: static operator wiki published through GitHub Pages.

## Confirmed Baselines

- Monolithic OAI reference: working reference, about `150 Mb/s` observed.
- Ethernet CU/DU with SIB8: working canonical rollback candidate, about `19-23 Mb/s` observed.
- Wi-Fi CU/DU with SIB8: working wireless-backhaul candidate, about `12 Mb/s` observed.

## Immediate Next Objective

Establish F1 backhaul through the Quectel module connected to `serber-minipc` using the target split topology: one 5GC and one shared CU on `serber-firecell`, one donor DU for the Quectel serving cell, and one access DU on `serber-minipc` with B210 serial `8002816`; access-DU F1 runs over WireGuard-over-Quectel.

## Operator TUI

Run `./scripts/oai-lab-tui` to launch and inspect the deployed lab modes:

- monolithic Core + gNB using the existing monolithic demo style;
- Ethernet CU/DU rollback with Core/CU on the CU host and DU/USRP on the DU host;
- PWS/SIB8 message apply for monolithic and Ethernet split modes;
- experimental caged Quectel tooling that predates the target donor-DU/access-DU topology and must not be treated as proof of it;
- guided phone throughput entry and timestamped local run records;
- read-only discovery for Raspberry Pi DU, `oai-pc` DU, and nrUE internet-through-radio workflows until they are validated.

The TUI first shows the active lab config and asks whether to use it. Operators
can keep the current environment/default config, choose the known
`serber-firecell` + `serber-minipc` or `serber-firecell` + `serber-pi` layouts,
or enter custom firecell/Pi IP addresses.

Default professor-demo lab targets:

```text
serber-firecell = serber@10.76.170.38
serber-minipc   = serber@10.76.170.40
serber-pi       = serber@10.76.170.18
```

Monolithic reference startup is pinned to `serber-firecell` to match the
existing monolithic demo workflow. Ethernet CU/DU startup first stops the
firecell monolithic core containers so the split core is the only active OAI CN
stack, then installs a temporary CU-side SCTP drop rule for the stale `oai-pc`
F1 peer at `10.76.170.90`. `Stop Ethernet CU/DU` removes that temporary rule.

It uses SSH and local commands only; it does not store passwords.

See `docs/tui/TUI.md`, `docs/tui/TUI_DEMO_GUIDE.md`, and `docs/tui/TUI_DISCOVERED_COMMANDS.md` for details.

## Security Warning

Secrets are never stored here. Use `conf/local/lab.env`, SSH config/agents, local ignored secret files, and sanitized evidence only.
