# oai-cu-du-lab

Private canonical context for an OAI 5G NR CU/DU split research lab.

## Objective

Investigate an OAI CU/DU split that can broadcast SIB8/PWS messages and later carry F1 over a wireless backhaul suitable for a lightweight or drone-carried DU.

## Current Status

Phase 1 contains documentation, inventory, audit reports, and future experiment templates only. Scripts, runtime configs, OAI source, and patches remain outside this repository until a later migration phase.

## Repository Purpose

This repository gives future agents a clean starting point for deployment-oriented work without requiring them to rediscover old public repositories.

## Directory Overview

- `docs/`: concise system, baseline, security, roadmap, and runbook context.
- `inventory/`: compact machine-readable host, radio, and baseline inventory.
- `experiments/`: future experiment index and report template.
- `prompts/`: reusable prompt skeletons for future agents.
- `patches/`: empty future patch areas.
- `conf/`: templates and generated-config placeholders.
- `scripts/`: empty placeholder for future vetted scripts.
- `audit/`: source repository audit, exposure report, and migration map.

## Confirmed Baselines

- Monolithic OAI reference: working reference, about `150 Mb/s` observed.
- Ethernet CU/DU with SIB8: working canonical rollback candidate, about `19-23 Mb/s` observed.
- Wi-Fi CU/DU with SIB8: working wireless-backhaul candidate, about `12 Mb/s` observed.

## Immediate Next Objective

Establish F1 backhaul through the Quectel module connected to `serber-minipc`, while keeping the USRP B210 on `serber-minipc` for local 5G access.

## Security Warning

Secrets are never stored here. Use placeholders, local ignored secret files, and sanitized evidence only.
