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

## Confirmed Baselines

- Monolithic OAI reference: working reference, about `150 Mb/s` observed.
- Ethernet CU/DU with SIB8: working canonical rollback candidate, about `19-23 Mb/s` observed.
- Wi-Fi CU/DU with SIB8: working wireless-backhaul candidate, about `12 Mb/s` observed.

## Immediate Next Objective

Establish F1 backhaul through the Quectel module connected to `serber-minipc`, while keeping the USRP B210 on `serber-minipc` for local 5G access.

## Operator TUI

Run `./scripts/oai-lab-tui` to launch and inspect the deployed lab modes:

- monolithic Core + gNB with local USRP detection/reset;
- Ethernet CU/DU with Core/CU on the CU host and DU/USRP on the DU host;
- Wi-Fi GRE overlay for the verified wireless-backhaul baseline;
- Quectel/WireGuard F1 preflight, safety-gated until an independent donor path is configured.

First create the ignored local profile:

```bash
./scripts/oai-lab-tui --init-local-config
```

Then edit `conf/local/lab.env` for hostnames, paths, SSH options, and sudo behavior. The TUI uses SSH and local commands only; it does not store passwords.

See `docs/TUI.md` for details.

## Security Warning

Secrets are never stored here. Use `conf/local/lab.env`, SSH config/agents, local ignored secret files, and sanitized evidence only.
