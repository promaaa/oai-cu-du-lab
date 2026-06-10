# Nothing Phone User-Plane Handover Plan

## Objective

Resolve and validate the Nothing Phone user-plane internet-connectivity issue in the Ethernet CU/DU split mode.

## Hypothesis

The initial-access blockers were removed by:

- setting CPU frequency governors to `performance` on both CU/core and DU hosts;
- launching the DU softmodem with `sudo` so OAI can create real-time threads with affinity and priority;
- adding `--continuous-tx` to the DU launch in TDD mode.

If RACH and registration now complete but the phone still has no internet, the remaining fault is likely in PDU-session establishment, F1-U GTP-U transport, or core-side user-plane routing/NAT.

## Date

2026-06-09

## Topology

- Mode: Ethernet CU/DU split.
- Core and CU host: `serber-firecell`, management IP `10.76.170.38`.
- DU host and USRP B210 access radio: `serber-minipc`.
- Live DU management IP observed during the handover run: `10.76.170.109`.
- Commercial UE: Nothing Phone, subscriber seeded outside this repository as `<nothing-phone-imsi>`.
- Rollback baseline: Ethernet CU/DU with SIB8.

## Hosts And Hardware

- `serber-firecell`: OAI 5GC and CU.
- `serber-minipc`: OAI DU and USRP B210 access radio.
- USRP B210: access radio only.
- Nothing Phone: commercial UE for registration and user-plane validation.

## Repository Commit

To be recorded before executing validation.

## OAI Commit

`102965a669b9444857c27843ec8ce62780bf9d37`

## Configs/Patches Used

- Ethernet CU/DU rollback baseline configuration.
- SIB8/PWS patch set remains the rollback baseline feature set.
- DU runtime config is generated outside Git and must remain untracked.

## Current Handover State

The handover note reports that the core, CU, and DU were already running in Ethernet CU/DU split mode. It also reports three previously fixed blockers:

- both hosts had been running with `powersave` CPU governors, causing DU-side UHD overflows and missed uplink packets during RACH;
- the DU had been launched without enough privileges for OAI real-time scheduling and memory behavior;
- the DU had been running without `--continuous-tx`, increasing TDD downlink/uplink transition instability.

No validated UE internet result was included in the handover note. Do not mark this issue complete until the evidence gates below pass.

## Live Precheck

Checked on 2026-06-09 before phone-triggered validation:

- `serber-firecell` core containers were up and healthy.
- CU softmodem was running against the Ethernet split CU config.
- `serber-minipc` was observed on Ethernet management IP `10.76.170.109`.
- DU softmodem was running with `sudo -n setsid`, `-E`, and `--continuous-tx`.
- F1-U sockets were bound on UDP `2153`:
  - CU side: `10.76.170.38:2153`
  - DU side: `10.76.170.109:2153`
- NG-U socket was bound on the CU/core side at `192.168.71.129:2152`.
- F1-C SCTP was established between `10.76.170.109` and `10.76.170.38:38472`.
- CU logs showed earlier F1 setup retries with SCTP shutdowns, followed by a later association that reached cell-in-service state.
- AMF showed the gNB connected but the UE table empty during the checked window.
- No fresh RACH, UE registration, PDU session, or F1-U user-plane traffic was observed during the short watch window.

## Validation Sequence

1. Trigger a fresh attach by asking the operator to toggle Nothing Phone Airplane Mode on for about 3 seconds, then off.
2. Watch the DU log for RACH progress:
   - `initiating RA procedure`
   - `Msg3 scheduled`
   - Msg4 contention resolution or equivalent RRC setup progress
   - RRC Setup Complete
3. Check AMF logs for `<nothing-phone-imsi>` reaching `5GMM-REGISTERED`.
4. Check SMF and UPF logs for a successful PDU session, assigned UE IP, N4/UPF programming, and uplink/downlink TEIDs.
5. If registration succeeds but internet still fails, inspect GTP-U socket bindings on both CU and DU hosts:
   - F1-U: UDP `2153`
   - NG-U: UDP `2152` on the CU/core side
6. Capture packet summaries, not raw packet captures, while the phone attempts traffic:
   - DU side: F1-U traffic between `serber-minipc` and `serber-firecell` on UDP `2153`
   - CU side: matching F1-U traffic on UDP `2153`
   - core side: UE subnet traffic and NAT/routing state
7. Verify core-side IP forwarding and NAT for the UE subnet used by the deployed OAI CN.
8. Record UE state, packet summaries, routing/NAT summary, and throughput or failed-traffic evidence in a timestamped experiment directory.

## Commands To Run

Use these as operator prompts only. Do not commit raw command output without sanitizing it first.

```bash
ssh serber-minipc "tail -f /tmp/oai-du-ethernet.log"
ssh serber@10.76.170.38 "docker logs oai-cn5g-minipc-oai-amf-1 --tail 50"
ssh serber@10.76.170.38 "docker logs oai-cn5g-minipc-oai-smf-1 --tail 50"
ssh serber-minipc "sudo ss -lunp | grep -E '2152|2153'"
ssh serber@10.76.170.38 "sudo ss -lunp | grep -E '2152|2153'"
ssh serber-minipc "sudo timeout 20 tcpdump -nni any udp port 2153 -c 50"
ssh serber@10.76.170.38 "sudo timeout 20 tcpdump -nni any udp port 2153 -c 50"
```

## Evidence Gates

PASS requires sanitized evidence for all of the following:

- DU-side RACH completes beyond Msg3 and reaches RRC setup completion.
- AMF shows the Nothing Phone subscriber in registered state.
- SMF/UPF show a PDU session with UE IP and TEIDs.
- F1-U packets appear on both CU and DU sides over the expected Ethernet path.
- UE-originated traffic reaches the core/user-plane path and receives return traffic, or the exact failing hop is identified.
- Throughput or internet test outcome is recorded.

## UE Registration Outcome

Pending validation.

## SIB8/PWS Outcome

Not part of this troubleshooting step unless the rollback baseline is restarted.

## Throughput Result

Pending validation.

## Comparison To Baseline

Compare against the Ethernet CU/DU with SIB8 rollback baseline, which previously observed about `19-23 Mb/s`.

## Rollback Procedure

If validation regresses the Ethernet split baseline or leaves OAI in an uncertain state:

```bash
ssh serber@10.76.170.38 "sudo killall -9 nr-softmodem || true"
ssh serber-minipc "sudo killall -9 nr-softmodem || true"
```

Then restart Ethernet CU/DU from `./scripts/oai-lab-tui` and collect fresh sanitized baseline evidence.

## Next Action

Run the validation sequence above with the user present to toggle the Nothing Phone, then commit only the sanitized experiment evidence and a concise conclusion.
