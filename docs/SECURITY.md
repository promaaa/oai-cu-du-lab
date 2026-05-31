# Security

## Secret Handling Policy

This repository must contain only placeholders and sanitized evidence. Treat any value that authenticates a UE, host, tunnel, API, or database as secret.

## Prohibited Values

- UE `Ki`, `OPc`, `K`, subscriber database secrets, and raw SIM profiles.
- Passwords, SSH credential strings, tokens, API keys, and private keys.
- Unsanitized `.env` files.
- Raw logs or captures that include identifiers or credentials.

## Placeholder Strategy

Use names such as `<ue-imsi>`, `<ue-ki>`, `<ue-opc>`, `<ssh-user>`, `<secret-file>`, `<wireguard-private-key>`, and `<apn>`.

## Local Secret Injection

Runtime credentials belong in ignored local files under `secrets/` or environment variables supplied outside Git. Scripts migrated in Phase 2 must fail closed when required secret inputs are missing.

## Git History Remediation

Public repositories with exposed secrets require sanitizing current files and rewriting Git history before they can be considered clean. History rewrites require explicit approval and coordinated force-push.

## Rotation Rule

Any secret committed to a public repository must be rotated or replaced, even after history cleanup.

## Evidence Rule

Raw logs and packet captures stay untracked by default. Commit only minimized, sanitized excerpts after review.
