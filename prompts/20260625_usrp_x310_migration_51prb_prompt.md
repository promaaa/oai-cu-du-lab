# Prompt: Verify Access Cell on USRP X310 (51 PRBs / 30.72 MSps)

You are working in `/Users/promaa/Documents/oai-cu-du-lab` on `main`.

Goal: Verify the newly-configured access cell on the USRP X310 using a **51 PRB** (20 MHz) channel bandwidth at **30.72 MSps**. Confirm F1 split association, Nothing Phone 5G attachment, user-plane internet access, and PWS/SIB8 emergency alert reception.

Read first:
- `AGENTS.md`
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- Walks and plans in:
  - `/Users/promaa/.gemini/antigravity/brain/e1037bfa-f310-4d91-9803-87fe99de4fff/walkthrough.md`
  - `/Users/promaa/.gemini/antigravity/brain/e1037bfa-f310-4d91-9803-87fe99de4fff/implementation_plan.md`
  - `/Users/promaa/.gemini/antigravity/brain/e1037bfa-f310-4d91-9803-87fe99de4fff/task.md`

Current working config & accomplishments:
- **USRP X310 Integration:** Fronthaul access cell migrated from USRP B210 to USRP X310 (`192.168.10.3`). FPGA compatibility flashed and verified (`FPGA Version: 39.3` / compat `39.0` loaded).
- **CPU & NIC Tuning:** CPU governors set to `performance` on both hosts. NIC offloads and EEE disabled on `enp4s0` (minipc).
- **DU Config modified on minipc:** `/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf` updated to:
  - `dl_carrierBandwidth = 51;` and `ul_carrierBandwidth = 51;`
  - `initialDLBWPlocationAndBandwidth = 13750;` and `initialULBWPlocationAndBandwidth = 13750;` (RIV for 51 PRBs starting at PRB 0)
  - `absoluteFrequencySSB = 641280;` (Working operator channel for Nothing Phone scanning)
  - `dl_absoluteFrequencyPointA = 640656;` (Point A shifted to place the SSB lowest subcarrier exactly 16 PRBs above Point A, matching the `rb_offset = 16` required by CORESET#0 index 12 in TS 38.213 Table 13-4 and resolving the DU assertion crash).
- **TUI Update:** Modified `scripts/oai-lab-tui` to default `jumboFrames` to `true` and remove the `-E` flag from the DU command line to allow the native 30.72 MSps sampling rate without 3/4 sampling.
- **Ethernet Split Started:** Running `./scripts/oai-lab-tui --start-ethernet` completed with all PASS gates green. Both CU and DU are active and associated over F1-C. The DU is successfully streaming to the X310 at 30.72 MSps with 0 overruns and 0 packet drops.

Remaining verification tasks:
1. **Verify DU runtime logs & UHD streaming:**
   - Check `/tmp/oai-du-ethernet.log` on `serber-minipc` to ensure there are no overruns (`O`) or drops under load, and verify that `RU 0 rf device ready` remains active.
2. **UE Attachment & User Plane Verification:**
   - Toggle Airplane Mode on the Nothing Phone (verify APN is set to `"oai"`).
   - Check that it detects the cell, shows 5G bars, and registers successfully.
   - Run a ping and internet throughput test on the Nothing Phone to confirm user-plane connectivity.
3. **PWS / SIB8 Verification:**
   - Verify that the SIB8/PWS warnings are successfully received on the Nothing Phone.
4. **Clean up & Record Evidence:**
   - Save sanitized logs, packet captures, and throughput results in the experiment directory under `experiments/`.
   - Update `walkthrough.md` with final phone attachment metrics.

Critical rules:
- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, or packet captures.
- Preserve verified baselines.
- Keep generated configs out of Git.
- Commit messages, docs, and pushed changes should read like ordinary maintainer work; do not mention external AI tools.
