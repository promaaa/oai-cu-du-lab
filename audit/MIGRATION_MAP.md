# Migration Map

Do not migrate files in Phase 1. Every candidate below needs a security review before import.

| Source repository/file or directory | Future destination in `oai-cu-du-lab` | Rationale | Security review required | Migration status |
|---|---|---|---|---|
| `cu-du/patches/oai-pws-sib8-cu-du.patch` | `patches/sib8/oai-pws-sib8-cu-du.patch` | Core SIB8/PWS feature patch | Yes, scanned for secret patterns | Migrated |
| `cu-du/scripts/apply-pws-sib8-cu-du.sh` | `scripts/` or `patches/sib8/` helper | Patch application helper | Yes, remove remote paths and credential assumptions | Not migrated |
| `cu-du/conf/*.yml` | `conf/templates/ethernet-cu.yml`, `conf/templates/ethernet-du.yml` | Baseline config template source | Yes, retained only topology/radio facts; no subscriber material | Distilled, not copied |
| `cu-du/docs/PWS_SIB8_CU_DU_DEPLOYMENT.md` | `docs/` or experiment references | Verified SIB8 split evidence | Yes, reduce to concise sanitized evidence | Not migrated |
| `cu-du/roles/*` | `scripts/` | Build/start/stop patterns | Yes, remove secrets and live-machine assumptions | Not migrated |
| `cu-du-backhauling/scripts/setup-gre-policy-routing.sh` | `conf/templates/wifi-gre-overlay.yml` | Wi-Fi GRE backhaul setup/rollback pattern | Yes, retained parameters only; executable migration deferred | Distilled, not copied |
| `cu-du-backhauling/scripts/validate-working-config.sh` | `scripts/` | Baseline validation helper | Yes, ensure no generated config or secrets | Not migrated |
| `cu-du-backhauling/conf/*.yml` | `conf/templates/wifi-gre-overlay.yml` | Wi-Fi and Ethernet split templates | Yes, retained only useful overlay facts | Distilled, not copied |
| `cu-du-backhauling/BACKHAULING.md` | `docs/BASELINES.md` or experiment report | Wi-Fi GRE evidence and rollback details | Yes, strip identifiers and long command history | Not migrated |
| `cu-du-5g-backhauling/scripts/quectel-backhaul/` | `patches/backhaul-quectel/README.md`, `conf/templates/quectel-wireguard.yml` | Quectel detection, WireGuard, validation, rollback candidates | Yes, executable migration deferred due SSH/password/key assumptions | Distilled, not copied |
| `cu-du-5g-backhauling/docs/quectel-f1-backhaul.md` | `docs/ROADMAP.md`, `conf/templates/quectel-wireguard.yml` | Quectel partial evidence and circular-dependency analysis | Yes, identifiers/password notes omitted | Distilled, not copied |
| `cu-du-5g-backhauling/docs/5g-f1-backhaul.md` | `docs/ROADMAP.md` | Future RF backhaul planning | Yes, keep only deployment-relevant content | Not migrated |
| `kaust-5g-research/docs/Presentation/Research Progress Report 10.md` | `docs/BASELINES.md` or experiment archive | Monolithic and Wi-Fi/PWS summary evidence | Yes, sanitize identifiers and presentation noise | Not migrated |
| `kaust-5g-research/docs/Presentation/Research Progress Report 11.md` | `docs/ROADMAP.md` or Quectel experiment archive | Quectel progress evidence | Yes, redact identifiers | Not migrated |
| `kaust-5g-research/docs/Presentation/Research Progress Report 5.md` | `patches/rpi-du/README.md` | Raspberry Pi 5 DU migration context | Yes, retained only status and guardrails | Distilled, not copied |
| `kaust-5g-research/docs/Notes/5G_CU_DU_Research_Summary.md` | `docs/SYSTEM.md` context only | Drone/portable-DU direction | Yes, contains credentials and older conflicting facts | Not migrated |
