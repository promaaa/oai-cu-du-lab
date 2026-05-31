# Decisions

## ADR-001: One Canonical Private Repository

Use this private repository for future agent context, inventories, audits, templates, and vetted migration targets.

## ADR-002: Source Repositories Stay Unchanged In Phase 1

Old repositories are read-only evidence sources during Phase 1.

## ADR-003: External Pinned OAI Source

Do not vendor OAI. Clone OAI externally, pin every experiment by commit, and keep project changes as feature-separated patches.

## ADR-004: Ethernet CU/DU With SIB8 Is Rollback Baseline

The Ethernet split with SIB8 has the strongest current evidence and is the canonical rollback target.

## ADR-005: Secrets Excluded From Git

UE auth values, passwords, tokens, private keys, and raw subscriber material must never be committed.

## ADR-006: Raw Logs Stay Local

Runtime logs and packet captures remain gitignored unless sanitized and explicitly approved.

## ADR-007: Monolithic Is Reference Only

The monolithic deployment remains a reference baseline, not an actively maintained branch of work.
