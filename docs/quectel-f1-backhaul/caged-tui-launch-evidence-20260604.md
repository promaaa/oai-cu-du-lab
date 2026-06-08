# Caged Quectel F1 Backhaul TUI Launch Evidence

Date: 2026-06-04

Scenario: `Caged Quectel F1 Backhaul` from `scripts/oai-lab-tui --start-caged-quectel`.

This file is retained as historical evidence. The supported Quectel backhaul
target is now the single-CU firecell donor DU setup documented in
`single-cu-firecell-donor-launch-runbook.md`; do not launch a monolithic donor
gNB from this evidence note.

Result: **No PASS claimed**. After TUI fixes, the live launch reached the split CU/DU over the Quectel/WireGuard path and proved F1-C placement, WireGuard placement, and management-interface isolation. The final PASS gate remained blocked because no UE F1-U `UDP/2153` packets were observed during the phone-traffic validation window.

## Dynamic Values Observed

- Minipc SSH target: `serber-minipc`
- Minipc management route to firecell: `enp4s0`, source `10.76.170.109`
- Minipc WiFi address also present: `10.85.168.144`
- Quectel data interface: `wwan0`
- Quectel QMI device: `/dev/cdc-wdm0`
- Quectel PDU IP from latest successful QMI gate: `10.0.0.2/30`
- Quectel PDU gateway from latest successful QMI gate: `10.0.0.1`
- Firecell OAI bridge: `oai-cn5g-minipc`
- Firecell bridge addresses required for this run: `192.168.71.129/26` and `192.168.71.140/26`
- WireGuard interface: `wg-quectel-f1`
- WireGuard endpoint route from minipc: `192.168.71.129 via 10.0.0.1 dev wwan0 src 10.0.0.2`
- Firecell return route: `10.0.0.2 via 192.168.71.134 dev oai-cn5g-minipc src 192.168.71.129`

## Evidence Summary

Hardware gate passed:

- Minipc B210 detected with serial `8002816`.
- Quectel exposed `/dev/cdc-wdm0` and `/dev/ttyUSB0` through `/dev/ttyUSB4`.

Core gate initially exposed a missing runbook requirement:

- `oai-cn5g-minipc` had `192.168.71.129/26` but not `192.168.71.140/26`.
- The old donor-gNB path failed N2/N3 binding until the TUI was updated to add/verify `192.168.71.140/26`. Current runs use the firecell donor DU local-F1 path instead.

Subscriber provisioning gate passed:

- The TUI prompts for `QUECTEL_IMSI` or reads it from the local environment.
- The active split-core subscriber seed script ran through the active MySQL container.
- Sanitized database evidence showed the local subscriber record existed; raw subscriber identifiers and keys are intentionally omitted.

Donor gate passed after the runtime receiver-threshold fix:

- Donor config path: `/home/serber/monolithic/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-firecell-donor-single-core-51prb.conf`
- Runtime donor config path: `/tmp/oai-tui-firecell-donor-51prb-rxboost.conf`
- Donor log showed `Received NGSetupResponse from AMF`.
- Donor log showed `cell PLMN 001.01 Cell ID 22345678 is in service`.
- Donor log showed `sample_rate 30720000 Hz`.
- After modem registration reset, the modem reported attach on the donor NR cell.

Quectel PDU gate reported live QMI settings:

- `Connection status: connected`
- `IPv4 address: 10.0.0.2`
- `IPv4 subnet mask: 255.255.255.252`
- `IPv4 gateway address: 10.0.0.1`

Route and WireGuard gates passed after making the TUI derive hooks and routes from live QMI values:

- Minipc route used `192.168.71.129 via 10.0.0.1 dev wwan0 src 10.0.0.2`.
- Firecell return route used `10.0.0.2 via 192.168.71.134 dev oai-cn5g-minipc src 192.168.71.129`.
- Both WireGuard peers showed recent handshakes.
- Tunnel pings passed in both directions between `10.250.0.1` and `10.250.0.2`.

CU and DU gates passed:

- CU logs showed F1 SCTP socket creation for the WireGuard CU address and GTP-U binding on `10.250.0.1:2153`.
- DU logs showed `DU_handle_F1_SETUP_RESPONSE`, received F1 setup response, B210 detection, and radio sync.

Packet validation passed:

- F1-C SCTP heartbeat traffic was visible on `wg-quectel-f1`.
- WireGuard outer UDP was visible on `wwan0` using the live Quectel PDU address.
- Management Ethernet/WiFi captures showed no F1-C SCTP or F1-U `UDP/2153` during validation windows.
- A repeat full TUI launch at `20260604_143736_caged_quectel_f1_backhaul_start`
  again reached this state with F1-C SCTP on `wg-quectel-f1` and WireGuard
  outer UDP on `wwan0`.

UE/F1-U validation did not pass:

- The TUI prompted for phone traffic and captured `wg-quectel-f1` on both peers.
- No F1-U `UDP/2153` packets were observed in three phone-traffic attempts.
- The TUI correctly failed closed and did not print PASS.

Rollback evidence:

- `scripts/oai-lab-tui --rollback-caged-quectel` stopped only the caged Quectel DU and CU by config path.
- WireGuard was stopped on minipc and firecell.
- Management SSH to `serber-firecell` and `serber-minipc` remained available.

## TUI Fixes Made From The Full Launch

- Config-path process stop now filters actual `nr-softmodem` command names instead of using broad `pgrep -f`, avoiding accidental termination of the SSH wrapper process.
- Firecell core gate now restores/verifies `192.168.71.140/26` on `oai-cn5g-minipc`.
- Donor gate now fails if N2/N3 bind errors are present.
- The TUI provisions the caged Quectel subscriber through the active split core seed path, with sanitized evidence only.
- Current runs use the generated firecell donor DU local-F1 config; the old RX-boosted donor-gNB copy is not part of the supported Quectel backhaul flow.
- The TUI resets Quectel registration before PDU establishment and waits for an attached NR state.
- WireGuard hooks and routes now use the live QMI PDU IP/gateway instead of stale fixed values.
- WireGuard gate now restarts firecell first, then minipc, before bidirectional tunnel validation.
- The UE/F1-U gate now gives three phone-traffic attempts before failing closed.
- The TUI now has a `Validate Running Caged Quectel F1 Backhaul` action and
  `--validate-caged-quectel` CLI flag so the final phone/F1-U gate can be
  retried without relaunching donor, CU, or DU.
- Packet captures for management interfaces and F1-U peer checks now run in
  parallel, shortening the validation loop while preserving the same PASS
  requirements.

## Next Actions

- Generate caged phone traffic during the final TUI prompt and require F1-U `UDP/2153` on `wg-quectel-f1`.
- If no F1-U appears, inspect sanitized UE registration/PDU session state and CU/DU GTP-U counters before rerunning the final gate.
- Keep using the existing PASS gates: F1-C SCTP on `wg-quectel-f1`, F1-U UDP/2153 on `wg-quectel-f1`, WireGuard UDP on the live Quectel data interface, and no F1 on management Ethernet/WiFi.
