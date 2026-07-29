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
