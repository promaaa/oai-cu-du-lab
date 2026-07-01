# Local Repository Cleanup Plan - CU/DU Split

Date: 2026-07-01

This plan covers local repositories under `/Users/promaa/Documents` that are
linked to the OAI CU/DU split lab. It is intentionally non-destructive: do not
delete or rewrite anything until the inventory, migration check, and validation
gates below pass.

## Goals

- Keep one canonical, clean deployment repository for the CU/DU split lab:
  `/Users/promaa/Documents/oai-cu-du-lab`.
- Preserve only the external OAI source checkout required for pinned source
  reference or rebuild work.
- Update the canonical repo with the currently used public configuration shape
  for `serber-firecell`, `serber-minipc`, and `serber-pi`.
- Keep generated configs, raw logs, packet captures, local environment files,
  subscriber material, credentials, and host secrets out of Git.
- Archive or remove superseded local repositories only after their remaining
  useful deltas are either migrated, documented as obsolete, or captured in a
  local quarantine bundle.

## Repository Classification

| Path | Decision | Reason |
|---|---|---|
| `/Users/promaa/Documents/oai-cu-du-lab` | Keep canonical | Clean control repo, current TUI, templates, inventory, patches, audit, and wiki. |
| `/Users/promaa/Documents/openairinterface5g` | Keep as external source checkout, not deployment repo | OAI source must remain external and pinned by commit. Cleanup should only remove local junk such as `.DS_Store` unless a fresh clone is cheaper. |
| `/Users/promaa/Documents/kaust-5G-research` | Keep separate documentation repo | Research reports and slides are still useful, but it should not be treated as deployment truth. |
| `/Users/promaa/Documents/monolithic` | Archive candidate after extracting remaining maintainer deltas | Monolithic is a reference baseline only. The local tree has modified files, so do not delete before review. |
| `/Users/promaa/Documents/cu-du` | Archive candidate after delta review | Historical Ethernet/SIB8 and Pi evidence source. It has local modifications and untracked files. Keep only distilled evidence/config in `oai-cu-du-lab`. |
| `/Users/promaa/Documents/cu-du-backhauling` | Archive candidate after delta review | Historical Wi-Fi GRE and early Quectel material. It has local modifications and mixed remotes. Migrate only sanitized logic/evidence. |
| `/Users/promaa/Documents/cu-du-5g-backhauling` | Archive/delete candidate after confirming migration completeness | Clean historical Quectel source. Current canonical repo already contains the cleaned rewrite and distilled docs. |

## Configuration Refresh Scope

Refresh versioned, sanitized public configuration only:

- `README.md`: default operator targets and supported modes.
- `docs/NETWORK.md`: current host roles, drift-prone aliases, and backhaul
  variants.
- `docs/BASELINES.md`: rollback and non-rollback status.
- `inventory/hosts.yml`: public host addresses, roles, attached equipment, and
  validation status.
- `inventory/baselines.yml`: current baseline status and OAI commit pin.
- `conf/lab.env.example`: safe defaults, placeholders, and operator-visible
  variables only.
- `docs/tui/*.md` and `wiki/`: update only if user-facing commands or topology
  wording changed.

Do not version `conf/local/lab.env`, generated runtime configs under `/tmp`,
raw packet captures, raw logs, private keys, passwords, UE credentials, or full
subscriber identifiers.

## Live Source-of-Truth Collection

Use direct host targets where aliases are known to drift:

- `serber@10.76.170.38` for `serber-firecell`.
- `serber@10.76.170.40` or verified `serber-minipc` alias for `serber-minipc`.
- `serber@10.76.170.18` or verified `serber-pi` alias for `serber-pi`.

Collect only sanitized evidence:

- host identity: `hostname`, public interface summary, and top-level retained
  directories;
- OAI commit: `git rev-parse HEAD` from each active OAI source tree;
- active config paths and checksums, not full configs if they contain local
  values;
- TUI verification output with direct host overrides;
- sanitized diff between versioned templates and active runtime assumptions;
- no raw tcpdump, raw logs, or local env files.

## Execution Plan

1. Freeze local state.
   - Record `git status --short --branch`, remotes, and `du -sh` for every
     candidate repo.
   - Create a local-only manifest under an ignored cleanup directory if large
     archives will be moved.

2. Verify canonical repo health.
   - Confirm `oai-cu-du-lab` is on `main` and clean before edits.
   - Run syntax checks for edited scripts and docs after each change.
   - Keep all feature patches under `patches/`.

3. Collect current host facts.
   - Run the TUI verify gate with direct host overrides and a temporary
     known-hosts file.
   - Reconfirm the active retained host paths from the prior cleanup:
     `serber-firecell` keeps `monolithic`, `docker`, `cu-du-minipc`, and
     `cu-du-minipc-backhaul`; `serber-minipc` keeps `cu-du`; `serber-pi` keeps
     `cu-du`.
   - Reconfirm OAI commit pin `102965a669b9444857c27843ec8ce62780bf9d37` where
     the active split configs depend on it.

4. Update the canonical repo.
   - Normalize current `serber-pi`, `serber-firecell`, and `serber-minipc`
     public config facts in inventory and example templates.
   - Replace stale hard-coded MiniPC addresses with alias-first wording plus
     direct-IP fallback where the latest host cleanup proved it necessary.
   - Keep local-only values as placeholders or ignored overrides.
   - Document rollback for every active path, with Ethernet CU/DU as the
     canonical rollback baseline.

5. Review historical repositories before archiving.
   - For each dirty repo, inspect local modifications and untracked files.
   - Migrate only sanitized, still-useful material into `oai-cu-du-lab`.
   - Mark anything obsolete in an audit note instead of copying stale configs.
   - For repositories containing old secrets or raw evidence, do not push or
     publish them until history cleanup and rotation decisions are explicit.

6. Clean local filesystem noise.
   - Remove ignored `.DS_Store`, `__pycache__`, `.pytest_cache`, stale logs, and
     local build/cache directories from kept repos.
   - In `openairinterface5g`, remove only local metadata noise unless a full
     reclone at the pinned commit is chosen.
   - In `kaust-5G-research`, keep reports/slides but remove local editor/cache
     noise only after checking the dirty report files.

7. Quarantine superseded repos before deletion.
   - Move archive candidates to a dated local quarantine outside the canonical
     repo, preserving Git metadata and dirty working trees.
   - Keep quarantine until the canonical TUI and rollback gates pass.
   - Delete quarantine only after the user confirms no historical delta is
     needed.

8. Validation gates before final deletion.
   - `git status --short --branch` clean in `oai-cu-du-lab`.
   - No tracked `.DS_Store`, raw `.log`, `.pcap`, credentials, or local env
     files in the canonical repo.
   - `node --check scripts/oai-lab-tui`.
   - `bash -n` for edited shell scripts.
   - `./scripts/oai-lab-tui --verify` with direct host overrides.
   - At minimum, Ethernet CU/DU rollback validation if any active config path
     changed.

## Safe Deletion Candidates

Delete immediately only after confirming they are ignored and untracked:

- `.DS_Store` files;
- `__pycache__` and test/tool caches;
- stale raw logs and captures outside evidence archives;
- generated runtime configs;
- local package/build byproducts not referenced by current scripts.

Do not delete immediately:

- dirty repositories;
- OAI source trees used by active host paths;
- quarantines from previous host cleanups;
- research reports/slides with unsaved local modifications;
- any repo that may contain the only copy of a still-unmigrated patch or
  baseline evidence.

## Final Target Layout

The desired local `/Users/promaa/Documents` state after approval is:

```text
oai-cu-du-lab/          canonical deployment/control repo
openairinterface5g/    external pinned OAI source reference, or replaced by a fresh pinned clone
kaust-5G-research/     separate research/reporting repo
_repo_cleanup_quarantine/YYYYMMDD/  temporary archived historical repos, removed only after validation
```

Historical deployment repos should disappear from the normal working surface
once their remaining useful deltas have been accounted for.
