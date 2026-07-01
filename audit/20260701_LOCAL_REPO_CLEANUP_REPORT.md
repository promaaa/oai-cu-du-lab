# Local Repository Cleanup Report - 2026-07-01

This report records the local `/Users/promaa/Documents` repository cleanup pass
for CU/DU split work.

## Scope

Canonical repo kept:

- `/Users/promaa/Documents/oai-cu-du-lab`

Other repos kept:

- `/Users/promaa/Documents/openairinterface5g` as an external OAI source
  checkout.
- `/Users/promaa/Documents/kaust-5G-research` as a separate research/reporting
  repository.

Deleted local historical deployment repos after explicit operator approval:

- `/Users/promaa/Documents/monolithic`
- `/Users/promaa/Documents/cu-du`
- `/Users/promaa/Documents/cu-du-backhauling`
- `/Users/promaa/Documents/cu-du-5g-backhauling`

## Live Host Facts Used

Direct SSH targets were used to avoid stale local aliases:

- `serber@10.76.170.38`: `serber-firecell`
- `serber@10.76.170.40`: `serber-minipc`
- `serber@10.76.170.18`: `serber-pi`

Observed active home-directory deployment roots:

- `serber-firecell`: `monolithic`, `docker`, `cu-du-minipc`,
  `cu-du-minipc-backhaul`
- `serber-minipc`: `cu-du`
- `serber-pi`: `cu-du`

Observed OAI commit where Git metadata was available:

```text
102965a669b9444857c27843ec8ce62780bf9d37
```

`serber-firecell` responded to a direct SSH command and exposed
`10.76.170.38` on `enp6s0`. A later TUI verify pass timed out on the firecell
SSH check, so firecell reachability should be rechecked before any radio
scenario is started.

## Canonical Repo Updates

- Updated TUI defaults to direct targets:
  `serber@10.76.170.38`, `serber@10.76.170.40`, and `serber@10.76.170.18`.
- Updated public host inventory and example local environment values for the
  currently verified MiniPC and Pi targets.
- Kept local-only `conf/local/lab.env`, generated configs, logs, captures, and
  subscriber values out of Git.

## Follow-Up Gates

Before claiming a lab scenario PASS after this filesystem cleanup:

1. Re-run `./scripts/oai-lab-tui --verify` with direct host overrides.
2. Revalidate Ethernet CU/DU rollback if any active config is changed on hosts.
3. Record sanitized evidence only; do not commit raw logs or packet captures.
