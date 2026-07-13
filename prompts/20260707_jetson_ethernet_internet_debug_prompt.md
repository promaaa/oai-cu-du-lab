# Next Agent Prompt: Jetson Ethernet Internet Debug

We are working in `/Users/promaa/Documents/oai-cu-du-lab`.

Read first:
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `experiments/20260702_jetson_du_baseline_alignment.md`
- `prompts/20260702_jetson_du_phone_pws_validation_prompt.md`

Follow the repo rules:
- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, or packet captures.
- Preserve Ethernet CU/DU with SIB8 as the rollback baseline.
- Work directly on `main` unless the user explicitly asks otherwise.
- Do not claim PASS without phone-visible evidence.
- Keep generated configs, raw logs, and packet captures out of Git.

Current user report before this handoff:
- Phone receives PWS.
- Phone shows 5G bars.
- Phone still does not have internet.
- User installed a new USB 10 Gbps hub and asked to rerun Jetson Ethernet CU/DU.

Current live topology:
- Jetson DU/access host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- Radio: USRP B210 serial `8002816`
- Jetson DU ID: `0xe02`
- Access cell: 106 PRB, not 51 PRB
- Jetson DU runtime:

```bash
sudo -n setsid taskset -c 1-5 ./nr-softmodem \
  -O /tmp/oai-tui-gnb-jetson-ethernet-runtime.conf \
  --log_config.global_log_level warning -E
```

Most recent rerun:

```bash
printf '\n' | ./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
```

Evidence directory printed by the TUI:

```text
experiments/20260706_211138_ethernet_cu_du_rollback_start
```

Important results from the new-hub rerun:
- Before UHD firmware load, the B210 briefly appeared on the USB 2.0 tree at `480M`.
- During TUI preflight/tuning, the B210 re-enumerated onto the new SuperSpeed hub path:
  - root hub: `10000M`
  - Genesys USB3.2 hub: `10000M`
  - B210: `usbfs`, `5000M`
  - ASIX USB Ethernet adapter: `5000M`
- TUI applied Jetson tuning:
  - `usbfs_memory_mb = 1000`
  - high socket buffers
  - RT runtime disabled
  - Jetson launch with `taskset -c 1-5`
- Static ARP entries were configured between firecell and Jetson to bypass switch-level ARP blocking.
- Jumbo MTU test failed, so the TUI fell back to TCP MSS clamping.
- Runtime config kept:
  - `gNB_DU_ID = 0xe02`
  - `local_n_address = "10.76.170.8"`
  - `remote_n_address = "10.76.170.38"`
  - `local_n_portd = 2153`
  - `remote_n_portd = 2153`
  - 106 PRB and B210 serial `8002816`
- CU started and accepted the Jetson DU.
- DU started with B210 and reached RF sync.
- PWS path passed at log level:
  - CU built `[SIB8]`
  - CU sent `F1AP_WRITE_REPLACE_WARNING`
  - DU logged `DU_handle_WriteReplaceWarning: sib_type=8`
  - DU logged `received Write Replace Warning Request from CU`
- DU overflow count remained `0`.
- CU socket state:
  - NG-U: `192.168.71.129:2152`
  - F1-U: `10.76.170.38:2153`
- DU socket state:
  - F1-U: `10.76.170.8:2153`

Current blocker after rerun:
- During the TUI final window and a follow-up watch loop, AMF showed the gNB connected but no UE row.
- DU logs did not show fresh `F1AP_INITIAL_UL_RRC_MESSAGE` or UE context setup during the watch window.
- UPF did not show a live UE data session, so there was no current UE IP to ping.
- Internet could not be validated in this rerun because no fresh UE/PDU session was observed.

Next steps for the next agent:
1. Ask the user to toggle airplane mode once, wait for 5G/PWS, and confirm whether the phone is actually registered or only camping.
2. Watch both sides while the user toggles:
   - On Jetson: look for `F1AP_INITIAL_UL_RRC_MESSAGE`, `F1AP_UE_CONTEXT_SETUP_RESP`, `F1AP_UE_CONTEXT_MODIFICATION_RESP`, `GTPU`, and release messages in `/tmp/oai-du-ethernet.log`.
   - On firecell: watch AMF registration/PDU setup and UPF `10.0.0.x`/`10.0.9.x` sessions.
3. Once a live UE data IP appears, ping that exact IP from `oai-cn5g-minipc-oai-ext-dn-1`; do not assume it is still `10.0.0.2`.
4. If external-DN ping passes but phone internet fails:
   - Verify APN/DNN on the phone is `oai`.
   - Capture sanitized F1-U summaries on firecell `enp6s0` for UDP `2153`.
   - Check UPF `tun0`, NAT/MASQUERADE, and default route through Jetson.
5. If UE does not register at all despite bars/PWS:
   - Treat it as phone attach/cell-selection/RRC, not an internet bug yet.
   - Verify the phone is selecting the lab PLMN and not only camping for system information/PWS.
   - Recheck DU logs for RACH/RRC messages immediately after airplane-mode toggle.
6. Do not change the working pieces unless evidence points there:
   - Keep B210 on the new SuperSpeed path at `5000M`.
   - Keep Jetson DU ID `0xe02`.
   - Keep F1-U ports on UDP `2153`.
   - Keep 106 PRB; do not switch to 51 PRB.
   - Keep the rebuilt Jetson SIB8/PWS DU patch.

Useful commands:

```bash
ssh serber@10.76.170.8 'lsusb -t; ss -lunp | egrep "2152|2153|nr-softmodem"; grep -Ei "INITIAL_UL|UL_RRC|UE_CONTEXT|RNTI|GTPU|release|WriteReplace|Write Replace|SIB8|overflow|ERROR" /tmp/oai-du-ethernet.log | tail -120; grep -c ERROR_CODE_OVERFLOW /tmp/oai-du-ethernet.log'
```

```bash
ssh serber@10.76.170.38 'ss -lunp | egrep "2152|2153|nr-softmodem"; docker logs --tail 220 oai-cn5g-minipc-oai-amf-1 2>&1 | grep -Ei "5GMM|REGISTERED|Registration|Deregistration|PDU|release|gNB|UEs|9449|ERROR|WARN" | tail -80; docker logs --tail 220 oai-cn5g-minipc-oai-upf-1 2>&1 | grep -E "UE IPv4|10\\.0\\.|PFCP switch|SEID|not found|pack_in_core" | tail -80'
```

```bash
ssh serber@10.76.170.38 'docker exec oai-cn5g-minipc-oai-ext-dn-1 ping -c 5 -W 1 <LIVE_UE_DATA_IP>'
```

Success criteria:
- B210 remains on USB SuperSpeed (`5000M`) through the new hub.
- F1-C and F1-U stay on Ethernet between `10.76.170.38` and `10.76.170.8`.
- DU overflow count remains `0` or acceptably low.
- Phone-visible 5G bars are present.
- Phone-visible PWS is received.
- UE registers in AMF and receives a data PDU session.
- External-DN ping to the live UE data IP passes.
- Phone browser or speed test has internet.

Do not claim PASS until all of those are true and sanitized evidence is recorded.
