# Jetson Ethernet Internet Debug

Date: 2026-07-07

## Goal

Debug the current Jetson Ethernet CU/DU state after the new USB 10 Gbps hub
rerun, without changing the working RF/F1/PWS pieces.

## Live Topology

- DU/access host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- Radio: USRP B210 serial `8002816`
- Jetson DU ID: `0xe02`
- Access cell: 106 PRB
- F1-U ports: CU `10.76.170.38:2153`, DU `10.76.170.8:2153`

## Sanitized Evidence

Observed at about 09:51-09:53 Asia/Riyadh:

- Jetson B210 remained on the SuperSpeed path at `5000M`.
- Jetson ASIX USB Ethernet adapter remained on the SuperSpeed path at `5000M`.
- Jetson DU was listening on UDP `10.76.170.8:2153`.
- CU/core was listening on NG-U `192.168.71.129:2152` and F1-U
  `10.76.170.38:2153`.
- Runtime config preserved:
  - `gNB_DU_ID = 0xe02`
  - `local_n_address = "10.76.170.8"`
  - `remote_n_address = "10.76.170.38"`
  - `local_n_portd = 2153`
  - `remote_n_portd = 2153`
  - B210 serial `8002816`
- DU log contained the PWS handler path:
  - `DU_handle_WriteReplaceWarning: sib_type=8`
  - `received Write Replace Warning Request from CU`
- DU overflow count remained `0`.
- AMF showed the gNB connected, but the UE table was empty during the watch
  window.
- UPF and SMF did not show a fresh `10.0.0.x` or `10.0.9.x` UE session during
  the watch window.
- Core routing/NAT pieces from the earlier Jetson internet fix were still
  present:
  - `10.0.0.0/16 via 192.168.71.134 dev oai-cn5g-minipc`
  - NAT masquerade for `10.0.0.0/16`
  - default route via Jetson on `enp6s0`

## Current Blocker

No fresh UE registration or PDU session was observed, so there was no live UE
data IP to ping from the external DN container. The current evidence points to
an attach/cell-selection/RRC gate before user-plane internet validation.

Do not claim internet PASS from this window. Phone-visible PWS and 5G bars are
not sufficient unless AMF registration, a live data PDU session, external-DN
reachability, and phone browser or speed-test internet are also observed.

## Next Action

Ask the operator to toggle airplane mode once while the logs are being watched.
During the toggle, check:

- Jetson DU log for `F1AP_INITIAL_UL_RRC_MESSAGE`,
  `F1AP_UE_CONTEXT_SETUP_RESP`, `F1AP_UE_CONTEXT_MODIFICATION_RESP`, RACH/RNTI
  activity, GTP-U, and release messages.
- AMF logs for registration and PDU-session activity.
- UPF/SMF logs for the live UE data IP.

If a live UE data IP appears, ping that exact IP from
`oai-cn5g-minipc-oai-ext-dn-1`. If external-DN ping passes but the handset still
has no internet, then verify the phone APN/DNN is `oai` and collect only
sanitized F1-U summaries on UDP `2153`.

## Follow-Up: PWS But No 5G

The operator later reported that the phone received PWS but did not show 5G.
Fresh checks changed the diagnosis:

- DU logs showed fresh `F1AP_INITIAL_UL_RRC_MESSAGE`, UL RRC messages, UE
  context setup/modification responses, and ongoing SRB activity.
- AMF showed the UE in `5GMM-REGISTERED` state.
- The first PDU-session attempts for `ims` and `oai` failed because AMF could
  not select an SMF: `SMF Selection, no SMF candidate is available`.
- SMF config already advertised the expected `oai`, `ims`, `openairinterface`,
  and `default` DNNs for SST `1`.
- The SMF process was reachable, but it had stopped producing fresh SMF logs
  and NRF discovery returned no SMF candidate.

Action taken:

- Restarted only `oai-cn5g-minipc-oai-smf-1` on the core host.
- The restarted SMF re-registered with NRF as `nfType: SMF`, advertised the
  expected DNN list, discovered the UPF, and completed PFCP association.

Post-restart evidence:

- AMF selected SMF successfully for `ims` and `oai`.
- SMF created active PDU sessions:
  - IMS-like session: `10.0.9.2`
  - data session: `10.0.0.2`
- UPF installed PFCP rules for both sessions.
- External DN ping to live UE data IP `10.0.0.2` partially passed:
  `5 transmitted, 3 received, 40% packet loss`.
- DU overflow count increased to `1`, and DU logs included RA-window noise, so
  the data path is alive but radio stability still needs handset-visible
  confirmation and possibly RF/MCS cleanup.

Status after this follow-up:

- PWS path: network-side pass.
- UE registration: network-side pass.
- PDU session: network-side pass after SMF restart.
- External-DN reachability: partial pass with packet loss.
- Phone-visible 5G and internet: waiting for operator confirmation after the
  SMF restart.

## Follow-Up: 6.5 Mbps Phone Throughput

The operator later measured about `6.5 Mbps` on the phone. This confirms that
the handset-visible internet path is alive, but it is still below the Raspberry
Pi and MiniPC Ethernet baselines.

Additional checks after the phone speed report:

- External-DN ping to the live UE data IP `10.0.0.2` improved to `20/20`
  replies, `0%` packet loss, with about `20 ms` average RTT.
- UPF still had PFCP rules for `10.0.0.2`.
- Jetson stayed in `MAXN_SUPER`, CPU governors were `performance`, and clocks
  were locked, so the immediate bottleneck was not basic power mode.
- DU overflow count had increased to `22`.
- DU logs contained repeated UE context modification activity, `UE_CONTEXT`
  release events, RA-window scheduling noise, and `ERROR_CODE_OVERFLOW`.
- AMF showed repeated PDU-session setup failures with `UE_NOT_RESPONDING` for
  the IMS-like session, while the UE remained registered.
- The B210 remained on the USB SuperSpeed tree at `5000M`.
- The ASIX USB Ethernet adapter was present on the SuperSpeed tree, but its
  network interface `enx6c1ff774eca6` had no carrier and was not carrying F1.
- The active Jetson F1 interface was the integrated `enP8p1s0` link at
  `1000Mb/s`, address `10.76.170.8`.

Interpretation:

The core and user-plane routing are no longer the main blockers. The remaining
throughput gap is most consistent with Jetson access-radio/runtime stability:
USB/RF overflows, UE responsiveness during bearer setup, and possibly scheduler
or RF-link quality. The new hub fixed the B210 SuperSpeed path, but the active
Ethernet F1 path is still the Jetson integrated 1 GbE interface, not the ASIX
5 GbE adapter.

Recommended next checks:

1. Run a synchronized phone speed-test window while collecting DU scheduler
   lines for MCS, BLER, LCID byte deltas, and overflows.
2. Compare the Jetson runtime against the Pi/MiniPC runtime for scheduler
   parameters, especially DL/UL MCS floors, BLER targets, PUCCH/PUSCH targets,
   and MSS clamp behavior.
3. Investigate whether the ASIX adapter should be cabled/configured as the
   Jetson F1 interface, or document that the active Jetson Ethernet path is the
   integrated 1 GbE NIC.
4. Keep the current SMF restart result in mind: if internet disappears again
   while registration remains, first check NRF SMF discovery before changing
   radio settings.

## Follow-Up: 7.3 Mbps Phone Throughput

The operator later measured about `7.3 Mbps` on the phone. This is another
incremental improvement over `6.5 Mbps`, but it remains below the Raspberry Pi
and MiniPC Ethernet baselines.

Additional checks after the `7.3 Mbps` report:

- AMF continued to show the UE in `5GMM-REGISTERED` state.
- External-DN ping to `10.0.0.2` still had `0%` packet loss over 20 probes.
- Ping latency was unstable: RTT ranged from about `8 ms` to `602 ms`, with
  about `207 ms` average.
- DU overflow count increased only slightly, from `22` to `23`.
- B210 remained on the USB SuperSpeed tree at `5000M`.
- Active F1 was still on the integrated Jetson `enP8p1s0` link at `1000Mb/s`;
  the ASIX USB Ethernet interface still had no carrier.

Interpretation:

The UE and core remain alive, and the data bearer is usable. The remaining
performance gap now looks like latency/jitter and radio/runtime scheduling
rather than a hard user-plane outage. The overflow counter is not racing upward,
but the RTT spikes and ongoing UE-context modification churn indicate the
Jetson path is still less stable than the Pi/MiniPC baselines.
