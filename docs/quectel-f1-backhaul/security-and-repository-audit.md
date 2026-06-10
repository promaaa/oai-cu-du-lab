# Security and Repository Audit

**Phase**: 0  
**Date**: 2026-06-01  
**Branch**: `main`

---

## 1. Repository State

| Item | Value |
|---|---|
| Canonical repo | `https://github.com/promaaa/cu-du-backhauling` → `/Users/promaa/Documents/oai-cu-du-lab` |
| Working branch | `main` |
| Remote branch | `origin/main` |
| Git history | Clean; all canonical commits are on `main` |
| OAI pinned commit | `102965a669b9444857c27843ec8ce62780bf9d37` |

---

## 2. Existing Files and Relevance

### Documentation (read-only source of truth)

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `docs/BASELINES.md` | Baseline status, throughput, rollback flags | Yes — Quectel entry is marked `partial_not_stable_baseline` |
| `docs/DECISIONS.md` | ADRs: secrets, rollback baseline, external OAI pin | Yes — must follow ADR-004 (Ethernet is rollback), ADR-005 (no secrets), ADR-003 (external OAI pin) |
| `docs/NETWORK.md` | Host roles, IP addresses, backhaul variants | Yes — Quectel `wwan0`, WireGuard tunnel, and firecell monolithic donor-gNB constraint documented here |
| `docs/ROADMAP.md` | Next objective: caged Quectel F1 backhaul | Yes — authoritative statement that same-cell full F1 and local-F1 donor-DU paths are not valid |
| `docs/RUNBOOK.md` | Pre-change evidence, rollback, validation sequence | Yes — must apply validation sequence before and after Quectel changes |
| `docs/SYSTEM.md` | CU/DU role split, F1 backhaul variants, SIB8/PWS role | Yes — clarifies B210 is access radio; Quectel is backhaul only |
| `docs/SECURITY.md` | Placeholder strategy, rotation rule, evidence rule | Yes — must not commit real credentials, logs, or keys |

### Configuration templates

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `conf/templates/ethernet-cu.yml` | Ethernet F1 CU config template (rollforward/rollback reference) | Yes — provides F1 endpoint values: CU `10.76.170.38`, DU `10.76.170.100` |
| `conf/templates/ethernet-du.yml` | Ethernet F1 DU config template (rollforward/rollback reference) | Yes — DU F1 local IP, B210 radio, band 78, PRB 106, SCS 30kHz |
| `conf/templates/quectel-wireguard.yml` | Quectel/WireGuard overlay config | Yes — WireGuard tunnel `10.250.0.1/2` and access DU F1 bind IPs |
| `conf/templates/wifi-gre-overlay.yml` | Verified Wi-Fi GRE F1 baseline | Yes — F1-C/F1-U addresses, policy routing table 100, throughput `~12 Mb/s` |

### Inventory records

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `inventory/hosts.yml` | Host roles, IPs, equipment | Yes — `serber-firecell` (Core+CU, `10.76.170.38`), `serber-minipc` (DU+USRP B210+Quectel, `10.76.170.100`) |
| `inventory/radios.yml` | Hardware status | Yes — USRP B210 is access radio; Quectel RM500Q-GL is intended backhaul, status `partial` |
| `inventory/baselines.yml` | Baseline records with rollback flags | Yes — Ethernet and Wi-Fi baselines are confirmed; Quectel is `partial_not_stable_baseline` |

### Patches

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `patches/sib8/oai-pws-sib8-cu-du.patch` | SIB8/PWS F1AP + MAC scheduler modifications | Yes — applies to OAI source tree; must be rebuilt after any OAI source change |
| `patches/sib8/README.md` | Patch scope and apply instructions | Yes |
| `patches/backhaul-quectel/README.md` | Placeholder for future Quectel backhaul scripts | Yes — executable migration deferred due to SSH/password/key assumptions |

### Source audits (read-only evidence)

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `audit/SECURITY_EXPOSURE.md` | Public repo credential exposure report | Yes — describes rotation requirement for committed secrets in source repos |
| `audit/SOURCE_REPOS.md` | Source repository inventory and useful material | Yes — maps `cu-du-5g-backhauling` (Quectel partial work) to canonical structure |
| `audit/MIGRATION_MAP.md` | File migration plan from source repos to canonical | Yes — Quectel detection/WireGuard/validation/rollback scripts are deferred |

### Scripts and TUI

| File | Purpose | Relevant for Quectel work |
|---|---|---|
| `scripts/oai-lab-tui` | Operator TUI for launching baselines | Yes — must support Quectel backhaul launch and firecell monolithic donor-gNB gate |
| `scripts/README.md` | TUI usage guide | Yes |
| `conf/local/lab.env` | Ignored local profile (SSH, paths, backhaul params) | Yes — firecell donor-gNB confirmation gate |

---

## 3. Prior Implementation Status

The source repository `cu-du-5g-backhauling` contains partial Quectel work:

- **Modem detection**: confirmed — USB enumeration, ModemManager, QMI bearer.
- **OAI cell lock**: the Quectel modem could lock to the local OAI access cell.
- **QMI packet data**: data sessions established on `wwan0`.
- **WireGuard overlay**: tunnel established from `serber-minipc` to `serber-firecell` over `wwan0`.
- **Partial F1 packet steering**: F1-C/F1-U packets observed through WireGuard interface.
- **Full F1 stable operation**: requires the current firecell monolithic donor-gNB target and packet-gated validation. The old same-cell and local-F1 donor-DU paths are not valid Quectel backhaul configurations.

**Root cause of prior failure**: Same-cell design creates circular dependency.
The DU needs F1 connectivity to the CU before the access cell can operate.
If the Quectel modem must attach to that same access cell to obtain F1, the system depends on a radio cell that itself depends on F1 already being established.

---

## 4. Secret-Handling Issues Found

Per `audit/SECURITY_EXPOSURE.md`, multiple source repositories contain committed secrets (UE `Ki`/`OPc`, IMSI values, SSH passwords, WireGuard private key references). None of those secrets are present in the canonical `oai-cu-du-lab` repository.

**Canonical repository status**: clean.
- No UE authentication values, IMSI, `Ki`, `OPc` committed.
- No passwords, SSH credentials, or API tokens committed.
- No raw logs or packet captures committed.
- `.gitignore` covers `secrets/`, `*.key`, `*.pem`, `*.log`, `conf/local/`, `conf/generated/`, `logs/`, `captures/`.

**Required guardrails for Quectel work**:
- WireGuard private keys: generated locally, never committed.
- Modem credentials: stored in ignored `secrets/` or environment variables.
- UE authentication: never enters this repository.
- SSH: key-based auth or agent, no password strings.

---

## 5. Branch and Commit References

| Item | Value |
|---|---|
| Current branch | `main` |
| Base commit | `19265d9` ("Make TUI launch deployed lab modes") |
| OAI commit | `102965a669b9444857c27843ec8ce62780bf9d37` |
| Confirmed baselines | Ethernet `~19-23 Mb/s`, Wi-Fi GRE `~12 Mb/s`, Monolithic `~150 Mb/s` |

---

## 6. Files Planned for Change

| File | Change type | Purpose |
|---|---|---|
| `docs/quectel-f1-backhaul/security-and-repository-audit.md` | Add | Phase 0 deliverable (this document) |
| `docs/quectel-f1-backhaul/ethernet-rollback-baseline.md` | Add | Phase 1 deliverable |
| `docs/quectel-f1-backhaul/modem-and-network-inventory.md` | Add | Phase 2 deliverable |
| `docs/quectel-f1-backhaul/ip-backhaul-validation.md` | Add | Phase 3 deliverable |
| `docs/quectel-f1-backhaul/f1-transport-migration-plan.md` | Add | Phase 4 deliverable |
| `docs/quectel-f1-backhaul/final-validation-report.md` | Add | Phase 5+ deliverable |
| `scripts/quectel-f1-backhaul/` | Add | Modem detection, WireGuard setup, F1 validation scripts |
| `conf/quectel-f1-backhaul/` | Add | WireGuard configs (no private keys), OAI config templates |

---

## 7. Dependency Warnings

1. **Circular dependency**: Full F1 over Quectel requires the firecell monolithic donor gNB. The modem must NOT attach to the same minipc access cell the DU is trying to backhaul, and the Quectel target must not use the failed local-F1 donor-DU path.
2. **Ethernet rollback baseline must remain restorable**: No change to OAI source, configuration generation, or routing should make Ethernet F1 unrecoverable.
3. **Management connectivity**: SSH access to both hosts must remain on the management interface during experiments. Policy routing must protect management traffic from the experimental Quectel path.
4. **OAI commit pin**: All changes assume OAI commit `102965a669b9444857c27843ec8ce62780bf9d37`. Rebuild and test SIB8/PWS if any OAI source tree is modified.
