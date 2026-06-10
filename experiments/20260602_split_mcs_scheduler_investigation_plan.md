# Experiment Plan: Ethernet Split MCS Scheduler Investigation

## Objective

Investigate why the verified Ethernet CU/DU split baseline remains near `19-23 Mb/s` while the monolithic reference is about `150 Mb/s`, with emphasis on whether downlink MCS is frozen at `0` because of scheduler tuning, missing CSI, missing HARQ feedback, or F1 timing.

## Hypothesis

The Ethernet split path is radio-capable but scheduler-limited. The leading hypothesis is that the DU scheduler is operating with conservative channel feedback, such as missing or stale CSI/CQI or HARQ state, causing downlink MCS to remain at `0`.

## Date

Planned on `2026-06-02`.

## Topology

- Monolithic reference: `serber-firecell` hosts the OAI core and gNB.
- Ethernet CU/DU rollback baseline: `serber-firecell` hosts core/CU; `serber-minipc` hosts DU and the USRP B210 access radio.
- UE validation: Nothing Phone or equivalent lab UE using sanitized, non-secret identifiers in any report.

## Hosts And Hardware

- `serber-firecell`: core/CU host.
- `serber-minipc`: DU host with USRP B210.
- USRP B210: local NR access radio.
- Quectel modem: not part of the first Ethernet investigation pass.

## Repository Commit

Record with:

```sh
git rev-parse HEAD
```

## OAI Commit

Expected pinned split baseline commit:

```text
102965a669b9444857c27843ec8ce62780bf9d37
```

Confirm on every OAI tree used for CU, DU, and monolithic reference before comparing results.

## Configs/Patches Used

- Start from the verified Ethernet CU/DU with SIB8 rollback baseline.
- Keep generated runtime configs out of Git.
- If an OAI code or config-template change is required, store it as a feature-separated patch under `patches/performance/`.
- Treat any forced-MCS or BLER-target change as an experimental tuning variant until it has sanitized evidence and rollback notes.

## Commands Executed

Use local operator commands, SSH sessions, or TUI actions already documented by the lab runbooks. Record only sanitized command summaries and non-secret outputs.

Read-only helper for the synchronized host/log window:

```sh
./scripts/collect-split-performance-window.sh 60
```

Run the helper only after intentionally starting the scenario under test. It does not start or stop OAI processes and does not collect raw packet captures.

Minimum measurement set for each 60-second test window:

- DU logs: `downlink_mcs`, `downlink_rounds`, `pucch0_dtx`, `average_rsrp`, CSI/CQI-related lines, HARQ ACK/NACK/DTX lines.
- CU logs: F1-C/F1-U state, SCTP counters, bearer state.
- F1 link capture summary: GTP-U throughput, SCTP heartbeat health, retransmission summary. Do not commit raw captures.
- Host interface counters: `ip -s link` on relevant Ethernet interfaces before and after the test.
- SCTP state: `ss -s` or equivalent SCTP counter summary.
- UE-side latency and throughput: ping/jitter and sustained throughput measurement.
- Active OAI commit and relevant sanitized radio/profile config summary.

## Investigation Steps

1. Remeasure the Ethernet CU/DU rollback baseline with synchronized metrics for a clean 60-second window. Success means reproducing about `19-23 Mb/s` and correlating it with observed MCS, HARQ, CSI/CQI, F1, and interface counters.
2. Rerun the monolithic reference with the same measurement set. Success means confirming about `150 Mb/s` and recording the scheduler MCS/CQI behavior that the radio can support.
3. Test a forced scheduler-tuning variant, such as `dl_min_mcs: 10`, bounded `dl_max_mcs`, and a wider downlink BLER target. Success means throughput rises materially without breaking attach, SIB8/PWS, or rollback.
4. If forced MCS does not improve throughput, inspect CSI/CQI reporting in DU logs, decoded RRC configuration, and F1-C summaries.
5. Inspect HARQ feedback health by comparing PUCCH/HARQ log counters, F1-C activity, and retransmission patterns.
6. Measure F1 timing and SCTP health between `serber-minipc` and `serber-firecell`; treat high latency, drops, or retransmissions as blockers before deeper code changes.
7. If runtime evidence points to OAI behavior, audit the pinned OAI scheduler and F1AP source externally, then record any proposed modification as a patch under `patches/performance/`.

## Evidence And Sanitized Log Extracts

To be collected during execution. Include only minimized sanitized excerpts. Do not commit raw logs, packet captures, subscriber material, UE secrets, passwords, tokens, private keys, or unredacted identifiers.

## UE Registration Outcome

To be recorded during execution.

## SIB8/PWS Outcome

The Ethernet split rollback baseline is expected to preserve SIB8/PWS. Record observed UE PWS behavior for every tuning or patch variant before claiming success.

## Throughput Result

To be recorded during execution.

## Comparison To Baseline

Compare every tuning or patch variant against:

- Monolithic reference: about `150 Mb/s`.
- Ethernet CU/DU rollback baseline with SIB8: about `19-23 Mb/s`.
- Wi-Fi CU/DU with SIB8: about `12 Mb/s`, informational only for this Ethernet-focused investigation.

## Conclusion

Not yet executed. Do not claim a fix until sanitized evidence shows throughput, scheduler behavior, UE state, and PWS/SIB8 outcome.

## Rollback Procedure

Return to the verified Ethernet CU/DU with SIB8 baseline. Remove any temporary MCS/BLER overrides, generated configs, firewall rules, captures, and debug logging that were used only for the experiment. Confirm rollback by rerunning attach, PWS/SIB8 observation, and a short throughput check against the documented `19-23 Mb/s` baseline range.

## Next Action

Execute step 1: synchronized Ethernet split baseline remeasurement with sanitized evidence collection.
