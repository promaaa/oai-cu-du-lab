# Phase 2 Plan

Migrate scripts, configs, and patches from source repos into this canonical repo.

## Migration Order

### 1. Quectel F1 Backhaul (Priority: HIGH)
**Why**: Current next objective.

Target: `scripts/quectel-f1/`

```
cu-du-5g-backhauling/scripts/quectel-backhaul/
├── 00_detect_quectel.sh
├── 02_setup_wireguard_firecell.sh    # strip keys/IPs
├── 03_setup_wireguard_minipc.sh      # strip keys/IPs
├── 05_generate_f1_configs_quectel.sh
├── 06_start_core.sh
├── 07_start_cu_over_quectel.sh
├── 08_start_du_over_quectel.sh
├── 11_attempt_full_f1_over_quectel.sh
├── rollback_live_f1_policy_to_eth.sh
└── common.sh
```

**Security**: Remove private keys, modem passwords, ICCID/IMSI from all scripts.

---

### 2. Wi-Fi GRE Backhaul (Priority: MEDIUM)
**Why**: Verified working baseline for wireless F1.

Target: `scripts/wifi-gre/`

```
cu-du-backhauling/scripts/
├── setup-gre-policy-routing.sh
├── validate-working-config.sh
├── deploy-cu.sh
└── deploy-du.sh
```

**Security**: Parameterize IPs, remove hardcoded credentials.

---

### 3. SIB8/PWS Baseline (Priority: MEDIUM)
**Why**: Rollback baseline must be reproducible from this repo.

Target: `scripts/pws/`

```
cu-du/
├── scripts/
│   ├── apply-pws-sib8-cu-du.sh
│   ├── deploy-cu.sh
│   ├── deploy-du.sh
│   └── validate-working-config.sh
├── patches/oai-pws-sib8-cu-du.patch  → patches/sib8/
└── conf/*.yml                         → conf/templates/
```

**Security**: Sanitize IMSI, Ki, OPc placeholders in configs.

---

### 4. RPi-DU Skeleton (Priority: LOW)
**Why**: Future work, not immediate.

Target: `scripts/rpi-du/` + `patches/rpi-du/`

- Review `cu-du/scripts/deploy-pi.sh` structure
- Create minimal stubs only

---

## What Stays Out of Git

| Category | Reason |
|---|---|
| Generated configs with live IMSIs | Secret risk |
| WireGuard private keys | Secret risk |
| Modem credentials / passwords | Secret risk |
| Raw logs / packet captures | Secret + noise |
| Live `.env` files | Secret risk |

---

## Migration Rules

1. **Review → Sanitize → Commit** — never skip security review
2. **Commit format**: `migrate: <feature> — <sanitization summary>`
3. **Scripts must fail closed** when required secrets are missing
4. **OAI commit**: `102965a669b9444857c27843ec8ce62780bf9d37` — pin it
5. **Evidence**: store only minimal sanitized excerpts, not full logs

---

## Expected Outcome

```
scripts/
├── quectel-f1/     # Quectel detection, WireGuard, F1, rollback
├── wifi-gre/        # GRE setup, validation, rollback
├── pws/             # SIB8/PWS patch, deploy, validation
└── rpi-du/          # minimal stubs (future)

conf/
├── templates/       # sanitized baseline configs
└── generated/      # .gitkeep only (local, not tracked)

patches/
├── sib8/            # verified oai-pws-sib8-cu-du.patch
├── quectel/         # future Quectel-specific patches
├── wifi-gre/        # future Wi-Fi GRE patches
└── rpi-du/          # future RPi-DU patches
```