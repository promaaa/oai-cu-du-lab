# Experiments

Use `TEMPLATE.md` for every future experiment. Store only sanitized reports and small evidence excerpts in Git.

## Plans

- `20260602_split_mcs_scheduler_investigation_plan.md`: planned Ethernet CU/DU split throughput investigation focused on MCS, CSI/CQI, HARQ, F1 timing, and scheduler tuning.
- `20260609_nothing_phone_user_plane_handover_plan.md`: handover-driven Ethernet CU/DU validation plan for Nothing Phone RACH, registration, PDU session, F1-U, and internet troubleshooting.
- `20260618_single_b210_rf_backhaul_plan.md`: temporary single-B210 RF backhaul/access probe plan on `serber-minipc` with Quectel suppressed, gated by an OAI dual-role architecture proof.

## Reports

- `20260628_pi_b210_106prb_uhd_limit.md`: Pi+B210 106 PRB debug. OAI reaches F1 setup and radio sync after adding the B210 61.44 MSps case. Pure UHD full-duplex 61.44 MSps still overruns, so the validated Pi TUI runtime follows the older working shape: `gNB_DU_ID = 0xe01`, `initialDLBWPsearchSpaceZero = 0`, and DU start with `-E` at 46.08 MSps.
- `20260702_jetson_du_baseline_alignment.md`: Jetson Orin Nano DU alignment against the MiniPC access-DU rollback identity. Confirms pinned OAI commit, B210 USB3, optimized Jetson launch, F1/UE log activity, bidirectional F1-U on UDP `2153`, external-DN reachability to the live UE IP, zero observed overflows, and the remaining no-PASS blockers: phone-visible internet and fresh PWS reception.
- `20260712_jetson_b210_new_cable_full_test.md`: Jetson B210 new-cable rerun. Host tuning and UHD discovery succeeded, but the B210 stayed on USB High-Speed `480M` instead of SuperSpeed `5000M`, so the TUI blocked OAI startup before any valid PWS, attach, internet, throughput, overflow, BLER, or MCS comparison.
- `20260602_split_mcs_scheduler_investigation_report.md`: Ethernet rollback route cleanup, runtime core PDU-session fix for the PWS-only symptom, and active-UE MCS-0 scheduler evidence.
- `20260618_single_b210_rf_backhaul_attempt.md`: failed-closed attempt of the experimental single-B210 mode blocked at `serber-minipc` discovery; no live minipc reachability, no Quectel/WireGuard changes were applied.
- `20260621_ethernet_mcs_unlock_report.md`: four-test permutation (baseline / MSS-clamp / forced-MCS / combined) of the Ethernet CU/DU split MCS unlock investigation. DL throughput progressed from 12.07 Mbps (untuned) to 17.18 Mbps (MSS + forced MCS). MCS ceiling rose from 7 to 10; BLER improved to 0.23 with combined tuning. Jumbo-frame MTU and CPU governor tuning identified as next actions.
- `20260625_x310_51prb_access_cell_verification.md`: USRP X310 access-cell verification. 106 PRB was tried and blocked by immediate UHD receive overflows on the 1 GbE minipc/X310 path, including with `-E` at 46.08 MSps. The lab was returned to a stable 51-PRB X310 state with F1-C and SIB8/PWS scheduling verified; phone attach, PWS reception, and user-plane internet remain unverified pending synchronized handset validation.
- `20260706_oai_pc_x310_transport_discovery.md`: oai-pc/X310 migration discovery and 106 PRB retry. `oai-pc` SSH worked and the X310 was moved to spare `enp3s0`, but the path negotiated only `1000Mb/s`, jumbo MTU failed, direct F1 to firecell was blocked by host-to-host reachability, and local X310 106 PRB tests on the cross-cell OAI tree reproduced transport failure: 46.08 MSps `-E` and native 61.44 MSps both reached `RU 0 rf device ready` then hit receive overflows.
