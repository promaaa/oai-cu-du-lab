# Security and evidence

## Never commit

- UE `Ki`, `OPc`, subscriber database secrets, IMSI dumps, or raw SIM profiles;
- passwords, tokens, private keys, or credential-bearing environment files;
- raw logs, packet captures, generated OAI configs, databases, or core dumps.

Use placeholders such as `<ue-imsi>`, `<ue-ki>`, `<ssh-user>`, and
`<wireguard-private-key>` in documentation.

## Local state

- Local configuration belongs in ignored `conf/local/`.
- Generated configuration belongs in ignored `conf/generated/` or remote
  runtime paths.
- Run evidence belongs under `~/.local/state/oai-cu-du-lab/runs/` or the path
  selected with `OAI_LAB_STATE_DIR`.

Only a minimized, reviewed conclusion should enter `STATUS.md`, `BASELINES.md`,
or a feature patch README.

## Publication check

This repository is public. Treat every tracked file and every commit as
immediately publishable; repository visibility is not a security boundary.

Before committing or publishing:

1. inspect the exact staged file list;
2. scan for credential and subscriber patterns;
3. ensure no raw evidence or generated configuration is staged;
4. verify host and radio identifiers are operational context, not secrets;
5. rotate any secret that was ever committed to a public repository.

Scan the complete reachable Git history, not only the working tree. Deleting a
credential from the current branch does not invalidate a published value.

## Historical exposure response

The historical `cu-du`, `cu-du-backhauling`, and related backhaul repositories
contained development context that included test subscriber or operational
material. They are not inputs to this artifact and are not part of the paper's
citation set. The exposed values were treated as compromised, revoked, and
replaced. Reuse of any historical repository additionally requires
verification that its published history was purged.

The canonical artifact imports only minimized, non-secret PWS facts: pinned
source revisions, the common test-profile digest, sanitized software markers,
and phone-side outcomes. Those facts are reviewed in
`docs/evidence/PWS-F1.md`; no historical database, subscriber file, generated
configuration, log, or capture is copied. Scientific reproducibility relies on
placeholders, patch digests, safe examples, and sanitized acceptance records,
never on operational subscriber values.
