# Security Exposure Report

All values are redacted. Source repositories appear public or historically public, so exposed credentials should be treated as compromised.

| Repository | File/path | Exposure type | Secret class | Public exposure risk | Required action | Value display |
|---|---|---|---|---|---|---|
| `cu-du` | `README.md` | Current tracked file and Git history | UE authentication value, identifier | High | Rotate UE credentials; sanitize file; rewrite history | redacted |
| `cu-du` | `roles/cn/seed-subscriber.sh` | Current tracked file and Git history | UE authentication value, identifier | High | Rotate UE credentials; replace with placeholders/local secret injection; rewrite history | redacted |
| `cu-du` | `roles/cn/health-check.sh` | Current tracked file and Git history | Identifier | Medium | Sanitize queries/output; rewrite history if identifiers are sensitive | redacted |
| `cu-du` | `scripts/check-health.sh`, `scripts/deploy-cu.sh`, `scripts/deploy-pi.sh`, `scripts/fresh-clone-remote.sh` | Current tracked file and Git history | Password/SSH credential pattern | High | Rotate passwords if real values were committed; remove password auth helpers or require local env; rewrite history | redacted |
| `cu-du` | Historical docs including `CODEX_JOURNAL.md`, `CURRENT_DEPLOYED_CONFIGURATION.md`, `INSTALL.md`, `JOURNAL.md`, `PLAN.md`, `REPRODUCIBLE_REDEPLOY_PLAN.md`, `RUN.md` | Git history | UE authentication value, identifier, password pattern | High | Rewrite history; rotate exposed secrets; retain sanitized private notes only | redacted |
| `cu-du-backhauling` | `README.md` | Current tracked file and Git history | UE authentication value, identifier | High | Rotate UE credentials; sanitize file; rewrite history | redacted |
| `cu-du-backhauling` | `conf/env.sh` | Current tracked file and Git history | UE authentication value, identifier | High | Remove real values; use ignored env file/template; rotate; rewrite history | redacted |
| `cu-du-backhauling` | `scripts/deploy-cu.sh`, `scripts/deploy-du.sh`, `scripts/check-health.sh` | Current tracked file and Git history | UE authentication value, identifier, password/SSH credential pattern | High | Remove embedded subscriber and password flows; rotate; rewrite history | redacted |
| `cu-du-backhauling` | `BACKHAULING.md` | Current tracked file and Git history | Identifier | Medium | Sanitize UE identifiers; rewrite history if public exposure must be removed | redacted |
| `cu-du-5g-backhauling` | `README.md` | Current tracked file and Git history | Password/SSH credential pattern | High | Remove example password export; rotate if real; rewrite history | redacted |
| `cu-du-5g-backhauling` | `conf/env.sh` | Current tracked file and Git history | UE authentication value, identifier | High | Replace with template and ignored local env; rotate; rewrite history | redacted |
| `cu-du-5g-backhauling` | `docs/quectel-f1-backhaul.md` | Current tracked file and Git history | IMSI/ICCID identifier, password note | Medium | Sanitize identifiers and password notes; rotate if real; rewrite history | redacted |
| `cu-du-5g-backhauling` | `scripts/quectel-backhaul/02_setup_wireguard_firecell.sh`, `03_setup_wireguard_minipc.sh` | Current tracked file and Git history | Private key handling location | Medium | Verify no generated private key values are committed; enforce local key generation only | redacted |
| `cu-du-5g-backhauling` | `scripts/quectel-backhaul/common.sh` | Current tracked file and Git history | Password/SSH credential pattern | High | Remove password forwarding pattern; rotate if real; rewrite history | redacted |
| `kaust-5g-research` | `docs/Notes/5G_CU_DU_Research_Summary.md` | Current tracked file and Git history | Password, identifier | High | Rotate passwords; sanitize; rewrite history | redacted |
| `kaust-5g-research` | `docs/Notes/Instructions.md` | Current tracked file and Git history | Identifier | Medium | Sanitize identifiers; rewrite history if required | redacted |
| `kaust-5g-research` | `docs/Presentation/Research Progress Report 6.md` | Current tracked file and Git history | UE authentication value, database password, identifier | High | Rotate UE credentials and DB password; sanitize; rewrite history | redacted |
| `kaust-5g-research` | `docs/Presentation/Research Progress Report 7.md` | Current tracked file and Git history | SSH password pattern | High | Rotate passwords; sanitize; rewrite history | redacted |
| `kaust-5g-research` | `docs/Presentation/Research Progress Report 11.md` | Current tracked file and Git history | IMSI/ICCID identifier | Medium | Sanitize identifiers; rewrite history if required | redacted |
| `kaust-5g-research` | Historical Obsidian and presentation paths | Git history | UE authentication value, identifier, password | High | Rewrite history; rotate exposed secrets; remove generated/vendor material | redacted |

## Remediation Procedure For Public Source Repositories

Do not execute this without explicit approval.

1. Create private backups of each repository.
2. Inventory all current valid secrets: UE auth material, SIM identifiers, host passwords, DB passwords, WireGuard keys, and API tokens.
3. Rotate or replace every secret that was committed to a public repository.
4. Edit current branches to replace secrets with placeholders and ignored templates.
5. Add strict `.gitignore` entries for `secrets/`, `.env*`, `*.key`, `*.pem`, logs, captures, generated configs, and subscriber material.
6. Run a secret scan on the sanitized working tree.
7. Rewrite history with `git filter-repo` or BFG to remove secret-bearing files/strings.
8. Re-run history scans after rewrite.
9. Force-push sanitized branches and tags only after explicit approval and coordination.
10. Invalidate old clones or require fresh clones.

## Proposed History Rewrite Commands

Example pattern only; customize per repository after confirming exact replacement rules:

```bash
git clone --mirror <public-repo-url> /tmp/<repo>.git
cd /tmp/<repo>.git
git filter-repo --replace-text /path/to/redaction-rules.txt --force
git grep -I -n -i -E '<secret-detection-patterns>' $(git rev-list --all)
git push --force --mirror
```

`redaction-rules.txt` must contain exact sensitive strings mapped to placeholders. Never publish that file.
