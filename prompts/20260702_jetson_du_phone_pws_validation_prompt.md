# Next Agent Prompt: Jetson DU Phone/PWS Validation

We are working in `/Users/promaa/Documents/oai-cu-du-lab`.

Read first:
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `experiments/20260702_jetson_du_baseline_alignment.md`
- `Research Progress Report 20.md`

Follow the repo rules:
- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, or packet captures.
- Preserve Ethernet CU/DU with SIB8 as the rollback baseline.
- Work directly on `main` unless the user explicitly asks otherwise.
- Do not claim PASS without phone-visible evidence.
- Keep generated configs, raw logs, and packet captures out of Git.

Current live topology:
- Jetson DU/access host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- Radio: USRP B210 serial `8002816`
- OAI commit on Jetson DU tree: `102965a669b9444857c27843ec8ce62780bf9d37`
- Jetson DU ID: `0xe02`
- Access cell: 106 PRB, not 51 PRB
- Jetson launch shape to preserve:

```bash
sudo -n setsid taskset -c 1-5 ./nr-softmodem \
  -O /tmp/oai-tui-gnb-jetson-ethernet-runtime.conf \
  --log_config.global_log_level warning -E
```

What was fixed already:
1. Jetson F1-U port mismatch:
   - The CU was sending F1-U to Jetson on UDP `2153`.
   - Jetson runtime was listening on UDP `2152`.
   - Live runtime was corrected to:
     - `local_n_portd = 2153`
     - `remote_n_portd = 2153`
   - `scripts/oai-lab-tui` now forces these values for `serber-jetson`.
2. Jetson DU-side PWS patch missing:
   - CU logs showed `[SIB8]` and `F1AP_WRITE_REPLACE_WARNING`.
   - Jetson DU initially logged no handler for F1AP procedure code `20`.
   - Existing repo patch `patches/sib8/oai-pws-sib8-cu-du.patch` was applied to the Jetson OAI checkout with `--exclude=sib8.conf`.
   - `nr-softmodem` was rebuilt on Jetson with `sudo -n cmake --build . --target nr-softmodem -j 4`.
   - Rebuilt binary contains `DU_handle_WriteReplaceWarning` and `received Write Replace Warning Request from CU`.

Current lab-side proof:
- Jetson DU is listening on `10.76.170.8:2153`.
- Jetson DU log shows:
  - `received Write Replace Warning Request from CU`
  - `got sync (ru_thread)`
  - `got sync (L1_stats_thread)`
  - overflow count `0`
- External DN can ping live UE data IP `10.0.0.2`.
  - Latest proof: `3 transmitted, 3 received, 0% packet loss`.
  - Earlier proof: `5 transmitted, 5 received, 0% packet loss`, RTT average about `26.5 ms`.
- Firecell NIC capture showed bidirectional F1-U:
  - `10.76.170.38:2153 <-> 10.76.170.8:2153`
- AMF showed UE registered and UPF recreated sessions for:
  - IMS-like `10.0.9.2`
  - data `10.0.0.2`

Current repo-side changes already made:
- `conf/templates/jetson-du.yml` added for Jetson DU.
- `scripts/oai-lab-tui` has Jetson Ethernet/Quectel presets, Jetson runtime stop cleanup, Jetson launch tuning, USB IRQ discovery, and Jetson F1-U port forcing to UDP `2153`.
- `inventory/hosts.yml` documents Jetson partial validation and remaining phone-visible PWS blocker.
- `experiments/20260702_jetson_du_baseline_alignment.md` documents the live evidence and no-PASS status.
- `Research Progress Report 20.md` summarizes the Jetson progress.

Remaining work:
1. Ask the user for the current phone state after toggling airplane mode once:
   - Does the Nothing Phone show 5G bars?
   - Does phone browser or speed test have internet?
   - Did the PWS alert appear?
2. If phone internet is not visible despite external-DN ping passing:
   - Verify APN/DNN is `oai`.
   - Recheck current UE IP from UPF before pinging.
   - Capture only sanitized packet summaries, not raw captures.
3. If PWS still does not appear on the phone:
   - Do not churn random configs.
   - First verify DU still logs `received Write Replace Warning Request from CU` after a fresh CU/DU restart.
   - Confirm SIB8 files on CU and Jetson match and use a fresh serial number.
   - Consider whether the handset suppresses the alert format, but only after network-side SIB8 scheduling is reconfirmed.
4. If the user confirms phone internet and PWS:
   - Update `experiments/20260702_jetson_du_baseline_alignment.md` with sanitized phone-visible evidence.
   - Update `inventory/hosts.yml` from partial to PASS only if all gates are met.
   - Update `Research Progress Report 20.md` to say phone-visible Jetson validation passed.
5. Run local checks before finishing:
   - `node --check scripts/oai-lab-tui`
   - `git diff --check`
   - secret scan as appropriate for touched files.

Do not claim PASS unless there is evidence for all of:
- phone-visible 5G bars,
- phone-visible internet or speed test,
- network-side external-DN/user-plane proof,
- DU-side PWS Write Replace handling,
- phone-visible PWS alert reception,
- zero or acceptable DU overflow behavior,
- rollback path still documented.
