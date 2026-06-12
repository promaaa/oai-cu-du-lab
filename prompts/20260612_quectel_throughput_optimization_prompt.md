# Prompt: Optimize Caged Quectel F1 Backhaul Throughput

You are working in `/Users/promaa/Documents/oai-cu-du-lab` on `main`.

Goal: optimize the now-working caged Quectel F1 backhaul throughput without breaking the PASS gates. Current Fast.com result on the Nothing Phone is about `5.5 Mb/s`, lower than the prior Ethernet CU/DU split baseline of about `19-23 Mb/s`.

Read first:

- `AGENTS.md`
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `docs/quectel-f1-backhaul/single-cu-firecell-donor-launch-runbook.md`
- `experiments/20260612_caged_quectel_access_f1u_recovery.md`
- `experiments/20260602_split_mcs_scheduler_investigation_report.md`
- `experiments/20260602_split_mcs_scheduler_investigation_plan.md`

Current working config:

- One 5GC + CU + monolithic donor gNB on `serber-firecell`.
- Minipc access DU on `serber-minipc` with B210 serial `8002816`.
- Quectel on donor PCI `1` / TAC `2`.
- Nothing Phone on access PCI `0` / TAC `1`.
- Access cell: n78, SSB `641280`, PointA `640008`, 106 PRB, `att_tx=3`, `att_rx=12`.
- Firecell donor runtime: `FIRECELL_DONOR_ATT_TX=24`, `att_rx=0`, `prach_dtx_threshold=100`.
- F1 over `wg-quectel-f1`: CU `10.250.0.1`, DU `10.250.0.2`.
- QMI PDU observed in the PASS run: `10.0.0.3/29` via `10.0.0.4`, but do not assume this is stable; always parse live QMI settings.
- Minipc CPU governors must be `performance` before DU launch.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37`.

PASS gates to preserve:

- Quectel donor registration on PCI `1` / TAC `2`.
- Access DU PCI `0` / TAC `1` in service.
- Nothing Phone registered on access cell, not donor.
- PWS/SIB8 delivered.
- F1-C SCTP on `wg-quectel-f1`.
- F1-U UDP/2153 on `wg-quectel-f1` during phone traffic.
- WireGuard outer UDP on `wwan0`.
- No minipc F1 on management Ethernet/Wi-Fi.
- Phone internet or throughput result recorded.

Critical rules:

- No secrets in Git or final output: no full IMSIs, Ki, OPc, passwords, private keys, raw packet captures, or unsanitized logs.
- Work directly on `main`.
- Do not create branches unless explicitly asked.
- Do not claim improvement without sanitized evidence: UE state, packet summaries, scheduler stats, and phone throughput.
- Keep generated runtime configs out of Git.
- Leave unrelated untracked files alone unless the user explicitly asks.

Suggested workflow:

1. Confirm the working baseline first:
   - `./scripts/oai-lab-tui --status`
   - `./scripts/oai-lab-tui --validate-caged-quectel`
   - record sanitized evidence in a new experiment note.
2. During a Fast.com run, collect a focused performance window:
   - DU MAC stats: RNTI, MCS, BLER, HARQ rounds, PUCCH DTX, CQI/CSI if available, RSRP/SNR.
   - CU/DU F1-U packet rates on `wg-quectel-f1`.
   - WireGuard byte counters and RTT.
   - Quectel donor serving-cell metrics and QMI settings.
   - CPU load/governors on firecell and minipc.
3. Compare with Ethernet split baseline:
   - old split throughput about `19-23 Mb/s`;
   - known issue: split downlink MCS may stick near `0` even when the UE is stable.
4. Investigate in small reversible steps:
   - access RF quality and donor/access isolation;
   - scheduler/MCS behavior (`dl_min_mcs`, BLER target, CQI/CSI availability);
   - WireGuard MTU and packet overhead;
   - Quectel donor link quality and PDU stability;
   - CPU/USB overruns or missed radio timing.
5. Change only one variable per run, record rollback, and compare throughput plus all PASS gates.

Definition of done:

- The optimized config is reproducible from documented inputs.
- It preserves all PASS gates.
- It records sanitized before/after evidence.
- It improves Fast.com throughput materially over `5.5 Mb/s`, or identifies the exact bottleneck and next action if no safe improvement is found.
