# Reproducibility

This repository is the canonical operational source for the CU/DU lab. A clean
clone contains the operator console, public configuration template, baseline
definitions, security rules, external-source pins, and feature-separated OAI
patches. Private configuration and raw evidence remain outside Git.

## Repository roles

| Repository | Role | Authority |
|---|---|---|
| `promaaa/oai-cu-du-lab` | Deployment, validation, evidence rules, rollback | Canonical |
| `promaaa/jetson-kernel-sctp` | Jetson SCTP kernel provisioning | Pinned build prerequisite |
| `promaaa/kaust-5G-research` | Reports, diagrams, and historical context | Non-authoritative |
| External OpenAirInterface source | CU/DU implementation | Pinned source dependency |

The exact external revisions are recorded in
[`dependencies.lock.yaml`](../reproducibility/dependencies.lock.yaml). Do not
replace an immutable commit with a branch name in a baseline or experiment
record.

The research repository may explain why a change was investigated, but its
older commands, host addresses, throughput values, and topology notes must not
override this repository.

## OAI source and patches

OAI remains outside this repository. Start from the locked commit and apply
only the patches required by the selected feature:

```bash
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
git checkout 102965a669b9444857c27843ec8ce62780bf9d37
git apply /path/to/oai-cu-du-lab/patches/sib8/oai-pws-sib8-cu-du.patch
```

The SIB8 patch is part of the rollback baseline. The Raspberry Pi sample-rate
patch is host-specific. The scheduler instrumentation is diagnostic only and
must be removed before preserving a rollback build.

Before applying a patch, verify its SHA-256 against the dependency lock. CI
checks every patch independently against the pinned OAI source.

## Evidence and acceptance

Runtime evidence stays under `~/.local/state/oai-cu-du-lab/runs/`. For every
accepted run, record the actual CU and DU OAI commits, local patch state, host
kernel and UHD versions, selected radio, transport, machine-side gates,
phone-side gates, and rollback result in sanitized evidence.

Do not publish raw logs, packet captures, generated configurations, subscriber
identifiers, credentials, or keys. Only reviewed conclusions belong in
`STATUS.md`, `BASELINES.md`, or a feature patch README.

## Updating a dependency

1. Validate the candidate in an external checkout.
2. Recompute patch checksums and run `git apply --check` against the candidate.
3. Run the static and reproducibility test suites.
4. Re-run the complete scenario acceptance gates.
5. Prove the MiniPC Ethernet rollback.
6. Update the lock, affected patch README, baseline classification, and rollback
   instructions together.

Changing a pin without new sanitized acceptance evidence does not create a new
baseline.
