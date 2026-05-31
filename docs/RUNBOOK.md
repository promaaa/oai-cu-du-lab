# Runbook

This is a future validation checklist. It is not an executable procedure for Phase 1.

## Pre-Change Evidence

- Record repository commit and OAI commit.
- Record topology, host roles, radio hardware, and backhaul path.
- Confirm rollback baseline availability.
- Save only sanitized logs or excerpts.

## Baseline Restoration Requirement

Before risky work, confirm that Ethernet CU/DU with SIB8 can be restored or that a documented rollback path exists.

## Generic Validation Sequence

1. Build the relevant OAI components from the pinned external OAI source.
2. Start the required Core, CU, DU, radio, and backhaul components.
3. Verify F1 connection and record sanitized evidence.
4. Verify UE registration.
5. Validate SIB8/PWS behavior where relevant.
6. Measure throughput with the method recorded in the experiment report.
7. Collect sanitized logs, packet summaries, and screenshots as needed.
8. Compare against the rollback baseline.
9. Document rollback and any deviations.

Do not include real credentials or unverified commands in this repository.
