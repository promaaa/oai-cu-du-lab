# Agent Context

This private repository is the canonical deployment context for an OpenAirInterface 5G NR CU/DU split lab that broadcasts SIB8/PWS messages and is moving toward wireless F1 backhaul through a Quectel modem while the USRP B210 remains the local access radio.

Read first: `README.md`, `docs/STATUS.md`, `docs/BASELINES.md`,
`docs/NETWORK.md`, and `docs/SECURITY.md`.

Immutable rules:
- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, or packet captures.
- Preserve verified baselines; Ethernet CU/DU with SIB8 is the rollback baseline.
- OAI source remains external and pinned by commit.
- Future modifications must be stored as feature-separated patches under `patches/`.
- Do not claim success without evidence: logs, packet captures, UE state, throughput, or PWS observation must be sanitized and recorded.
- Work directly on `main` unless the user explicitly asks for another branch. Do not create or push extra branches for normal repo updates.
- Commit messages, branch names, docs, and pushed changes should read like ordinary maintainer work; do not mention external tooling.

Workflow: read the baseline and security docs, make a small scoped change, pin the OAI commit, keep generated configs out of Git, collect sanitized evidence, compare against the rollback baseline, and document rollback.

Definition of done: the feature or deployment is reproducible from documented inputs, has sanitized evidence, does not regress the rollback baseline, contains no secrets, and records next actions.
