# Phase 2 Status

Phase 2 has started with an essential-only migration. The goal is to make this repo useful without turning it into a noisy mirror of the old repositories.

## Migrated

- `patches/sib8/oai-pws-sib8-cu-du.patch`: the core SIB8/PWS OAI patch, whitespace-normalized and scanned for obvious secret patterns.
- `patches/sib8/README.md`: patch source, expected OAI commit, and use rules.
- `conf/templates/ethernet-cu.yml`: sanitized CU/Core rollback baseline facts.
- `conf/templates/ethernet-du.yml`: sanitized DU/USRP rollback baseline facts.
- `conf/templates/wifi-gre-overlay.yml`: sanitized Wi-Fi GRE overlay facts.
- `conf/templates/quectel-wireguard.yml`: sanitized Quectel/WireGuard target facts and validation guardrails.
- `conf/templates/sib8.conf.template`: non-secret warning-message template.
- `scripts/README.md`: policy for keeping scripts small and vetted.
- Short README files under `patches/backhaul-quectel/`, `patches/performance/`, and `patches/rpi-du/`.

## Intentionally Not Migrated

- Old one-command deployment scripts.
- Password-based SSH wrappers.
- Subscriber database seed scripts.
- Generated OAI configs.
- Raw logs, captures, or long command diaries.
- Broad research notes and presentations.

## Why

The source scripts are useful evidence but too host-specific and secret-adjacent to import directly. Future executable scripts should be rewritten from the templates and runbook, not copied wholesale.

## Future Migration Criteria

A future script or config is worth adding only if it:
- supports a current workflow;
- has no secrets or subscriber values;
- is parameterized rather than hardcoded to a single run;
- fails closed when required local inputs are missing;
- writes generated outputs to ignored paths;
- has a clear rollback or validation role.

## Next Useful Additions

1. A small renderer that turns `conf/templates/*.yml` into local generated OAI configs.
2. A dry-run Quectel/WireGuard validator that checks prerequisites without changing host state.
3. A sanitized baseline-validation checklist script that only reads logs and prints pass/fail hints.

Anything larger should stay out until it proves it reduces confusion.
