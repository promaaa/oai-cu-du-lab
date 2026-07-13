# Next Agent Prompt: Jetson B210 New Cable Full Test

We are working in `/Users/promaa/Documents/oai-cu-du-lab`.

Read first:
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `prompts/20260707_jetson_ethernet_internet_debug_prompt.md`
- `experiments/20260707_jetson_ethernet_internet_debug.md`

Follow the repo rules:
- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, or packet captures.
- Preserve Ethernet CU/DU with SIB8 as the rollback baseline.
- Work directly on `main` unless the user explicitly asks otherwise.
- Do not claim PASS without phone-visible evidence.
- Keep generated configs, raw logs, and packet captures out of Git.

Current user update:
- The user installed a new cable for the USRP B210 on the Jetson Orin Nano.
- The goal is to run a full Jetson Ethernet CU/DU validation and determine whether the new B210 cable improves the previous throughput, overflow, and BLER problem.

Known topology:
- Jetson DU/access host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- Radio: USRP B210 serial `8002816`
- Jetson DU ID: `0xe02`
- Access cell: 106 PRB, not 51 PRB
- Expected F1 path: Ethernet between Jetson `10.76.170.8` and CU/core `10.76.170.38`
- Expected F1-U ports: UDP `2153` on both CU and DU

Known state before the new B210 cable:
- Phone-visible PWS passed.
- UE registration and PDU session eventually passed after fixing a stale SMF/NRF discovery state by restarting only the SMF container.
- Phone internet worked, but throughput was low:
  - about `6.5 Mbps`
  - then about `7.3 Mbps`
- This remained below the Raspberry Pi and MiniPC Ethernet baselines.
- External-DN ping to the live UE data IP eventually reached `0%` loss, but RTT was unstable with large spikes.
- DU logs accumulated overflows, reaching about `23` during validation.
- B210 was on USB SuperSpeed at `5000M`, but the old cable/hub path still had overflow and high-BLER symptoms.
- ASIX USB Ethernet was present on the hub but had no carrier. Active F1 was still on integrated Jetson `enP8p1s0` at `1000Mb/s`.

Important distinction:
- Do not treat USB `5000M` enumeration as success by itself.
- The new cable is successful only if it improves the live radio/runtime behavior: lower overflow count, lower BLER, stable UE context, stable RTT, and better phone throughput.

Full test plan:

1. Establish the hardware state before starting OAI.
   - Verify the B210 is seen on the expected USB tree.
   - Confirm the B210 stays at `5000M` before and after UHD firmware load.
   - Record whether the new cable is direct USB-C to USB-B or still through a hub.
   - Record what else is sharing the same USB root/hub path.
   - Check Jetson power mode, clocks, CPU governors, `usbfs_memory_mb`, and USB autosuspend.

2. Confirm the active network path.
   - Verify Jetson F1 IP is still `10.76.170.8`.
   - Verify CU/core IP is still `10.76.170.38`.
   - Confirm whether F1 is still on integrated `enP8p1s0` or has moved to a USB Ethernet interface.
   - Check negotiated link speed with `ethtool`.
   - Do not assume the ASIX path is active just because it appears in `lsusb`.

3. Start the Jetson Ethernet CU/DU stack from the repo TUI.

```bash
printf '\n' | ./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
```

4. During startup, verify these gates in order.
   - CU/core containers are healthy.
   - SMF is registered with NRF before UE PDU session validation.
   - CU accepts the Jetson DU.
   - F1-C is established.
   - F1-U sockets are present on UDP `2153`.
   - DU starts with B210 serial `8002816`.
   - B210 remains USB SuperSpeed at `5000M`.
   - PWS path is present in logs:
     - CU builds `[SIB8]`
     - CU sends `F1AP_WRITE_REPLACE_WARNING`
     - DU handles `Write Replace Warning Request`

5. Ask the user to validate phone-visible service.
   - Ask the user to toggle airplane mode once after the cell is ready.
   - Ask the user to report these separately:
     - 5G bars
     - PWS received
     - internet works
     - speed-test downlink/uplink
   - Do not merge PWS, 5G bars, attach, internet, and throughput into one PASS.

6. Watch attach and PDU session creation live.
   - On Jetson, watch RACH/RRC/F1AP/UE context/GTPU/release/overflow lines.
   - On CU/core, watch AMF registration, PDU session creation, SMF selection, UPF session creation, and UE IPv4 assignment.
   - If AMF logs show `SMF Selection, no SMF candidate is available`, restart only SMF, then recheck NRF registration and retry phone attach.
   - Do not restart the whole stack unless the evidence requires it.

7. Once the live UE data IP is known, prove user-plane reachability from the external DN.
   - Do not assume the UE data IP is still `10.0.0.2`.
   - Ping the exact live UE data IP from `oai-cn5g-minipc-oai-ext-dn-1`.
   - Run both a short ping and a longer ping to capture loss and RTT stability.

8. Measure the new-cable effect.
   - Capture overflow count at startup, after attach, after ping, and after phone speed test.
   - Capture BLER/MCS/LCID byte deltas if available from logs or TUI evidence.
   - Compare phone speed to the previous Jetson values:
     - previous bad lower point: about `6.5 Mbps`
     - previous best observed point: about `7.3 Mbps`
   - Compare to baselines:
     - Raspberry Pi tuned Ethernet: about `21-23 Mbps`
     - MiniPC tuned Ethernet: about `89 Mbps`
   - A result near `7.3 Mbps` means the cable did not solve the main throughput problem.

Useful commands:

```bash
ssh serber@10.76.170.8 'hostname; date; lsusb -t; ip -br addr; ip route; for i in /sys/class/net/*; do n=${i##*/}; [ -e "$i" ] && printf "\n== %s ==\n" "$n" && ethtool "$n" 2>/dev/null | egrep "Speed|Duplex|Link detected" || true; done; cat /sys/module/usbcore/parameters/usbfs_memory_mb 2>/dev/null; grep . /sys/bus/usb/devices/*/power/control 2>/dev/null | head -40'
```

```bash
ssh serber@10.76.170.8 'ss -lunp | egrep "2152|2153|nr-softmodem" || true; grep -Ei "INITIAL_UL|UL_RRC|UE_CONTEXT|RNTI|GTPU|release|WriteReplace|Write Replace|SIB8|overflow|ERROR_CODE_OVERFLOW|ERROR|BLER|MCS|LCID" /tmp/oai-du-ethernet.log | tail -180; printf "overflow_count="; grep -c ERROR_CODE_OVERFLOW /tmp/oai-du-ethernet.log 2>/dev/null || true'
```

```bash
ssh serber@10.76.170.38 'hostname; date; ss -lunp | egrep "2152|2153|nr-softmodem" || true; docker ps --format "table {{.Names}}\t{{.Status}}" | egrep "oai|NAME"; docker logs --tail 260 oai-cn5g-minipc-oai-amf-1 2>&1 | grep -Ei "5GMM|REGISTERED|Registration|Deregistration|PDU|SMF Selection|no SMF candidate|release|gNB|UEs|ERROR|WARN" | tail -120; docker logs --tail 260 oai-cn5g-minipc-oai-smf-1 2>&1 | grep -Ei "NRF|NF|Register|DNN|PDU|PFCP|UPF|ERROR|WARN" | tail -120; docker logs --tail 260 oai-cn5g-minipc-oai-upf-1 2>&1 | grep -E "UE IPv4|10\\.0\\.|PFCP switch|SEID|not found|pack_in_core" | tail -120'
```

```bash
ssh serber@10.76.170.38 'docker exec oai-cn5g-minipc-oai-ext-dn-1 ping -c 5 -W 1 <LIVE_UE_DATA_IP>; docker exec oai-cn5g-minipc-oai-ext-dn-1 ping -c 30 -W 1 <LIVE_UE_DATA_IP>'
```

If phone service fails:
- If PWS passes but no 5G registration appears, focus on phone attach/RRC/UE context, not internet.
- If registration appears but PDU session fails, check AMF SMF-selection logs and SMF NRF registration.
- If PDU session exists and external-DN ping passes but the phone has no internet, check phone APN/DNN, NAT, UPF route, and `tun0`.
- If throughput remains low with overflows, focus on B210 cable/USB path, BLER/MCS behavior, CPU scheduling, IRQ placement, and whether another USB device is sharing the bus.

Success criteria:
- New B210 cable path is documented.
- B210 remains at USB SuperSpeed `5000M` before and during OAI runtime.
- CU accepts Jetson DU and F1-C/F1-U are established.
- Phone receives PWS.
- Phone shows 5G service.
- UE registers in AMF.
- UE receives a data PDU session.
- External-DN ping to the live UE data IP passes with low loss and reasonable RTT.
- Phone internet works.
- Phone speed test is recorded.
- Overflow count and BLER/MCS evidence are compared against the previous `6.5-7.3 Mbps` Jetson result.
- Sanitized evidence is recorded in a new experiment note.

Do not claim PASS unless all phone-visible and network-side criteria are true.
