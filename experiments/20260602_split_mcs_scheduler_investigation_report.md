# Experiment Report: Ethernet Split MCS Scheduler Investigation

## Objective

Restore the Ethernet CU/DU rollback baseline after Quectel experiments and collect evidence toward why downlink MCS remains at `0`.

## Hypothesis

The low split-mode throughput is scheduler/feedback related rather than Ethernet capacity. Specifically, OAI initializes DL MCS to `dl_min_mcs` and only raises it after enough successful DL HARQ outcomes; missing UE traffic, missing CQI/SINR reports, or missed HARQ timing can keep MCS at `0`.

A separate "PWS only, no 5G data" symptom can occur when the RAN broadcasts
PWS and completes registration but the core fails PDU session establishment.

## Date

`2026-06-02`

## Topology

- Core/CU: `serber-firecell`, management IP `10.76.170.38`.
- DU/USRP: `serber-minipc`, management IP `10.76.170.100`.
- F1 target for this run: direct Ethernet management network.

## Repository Commit

Recorded by the collector metadata in the ignored runtime evidence directory.

## OAI Commit

The runtime logs show abbreviated build hash `102965a669`. Direct `git rev-parse HEAD` on the active source trees reported `9e67011af10f73264356366a59df7545349d9dab`, so the deployed source/build provenance needs cleanup before a final performance claim.

## Configs/Patches Used

- CU config: `gnb-cu-minipc.conf`.
- DU config: `gnb-minipc.conf`.
- No forced-MCS tuning was applied in this run.
- Added rollback-script cleanup for stale Quectel routes that can override Ethernet F1.
- Runtime AMF config was changed on the core host from `enable_smf_selection: yes` to `enable_smf_selection: no` after AMF logs showed SMF selection failures despite SMF/NRF being present.

## Commands Executed

Sanitized command summary:

```sh
./scripts/oai-lab-tui --start-ethernet
./scripts/collect-split-performance-window.sh 60
```

Additional read-only checks inspected routes, SCTP state, filtered OAI logs, AMF UE state, and OAI scheduler source.

## Evidence And Sanitized Log Extracts

Runtime evidence was collected in an ignored local directory:

```text
experiments/20260602_153538_split_performance_window/
experiments/20260602_184211_split_performance_window/
experiments/20260602_185129_split_performance_window/
experiments/20260603_072249_monolithic_speedtest_mcs_window/
```

Key evidence:

- Initial Ethernet startup failed to complete F1 because `serber-minipc` had stale Quectel routes sending `10.76.170.38` via `wwan0`.
- After deleting those routes, F1-C SCTP established over `enp2s0`: `10.76.170.100:57263 -> 10.76.170.38:38472`.
- F1 setup completed and SIB8/PWS configuration reached the DU.
- AMF showed `gNB-CU-MINIPC` connected, but the UE table was empty during the 60-second window.
- No UE scheduler stats, CQI reports, HARQ feedback lines, or MCS lines were emitted during the measurement window.
- DU-to-CU ping from the DU host reported `0%` packet loss but high scheduling/jitter: min/avg/max/mdev `3.408/74.572/173.776/39.246 ms`.
- CU-to-DU ping from the CU host immediately afterward was clean: min/avg/max/mdev `0.154/0.181/0.226/0.016 ms`.
- After the UE was made active, AMF logs showed registration and two PDU Session Resource Setup procedures for DNNs `oai` and `ims`.
- SMF logs showed `PDU_SESSION_ESTABLISHMENT_UE_REQUESTED`, N4 session modification responses, and PDU session status moving to active.
- UPF logs showed PFCP session establishment/modification activity for the UE sessions.
- During the active UE window, DU scheduler stats showed LCID 4 traffic counters present and increasing overall, while DL stayed at `MCS (1) 0` with BLER decaying to `0.00000`.
- Example active-window DU state: DL `dlsch_rounds 3743/314/1/0`, `dlsch_errors 0`, `pucch0_DTX 3`, `BLER 0.00000`, `MCS (1) 0`; UL `ulsch_rounds 4708/209/1/0`, `ulsch_errors 0`, `MCS (1) 0`, SNR around `12.0 dB`; average RSRP around `-109` to `-111`.
- Active-window DU-to-CU ping still had `0%` loss but nontrivial jitter: min/avg/max/mdev `0.880/20.678/71.218/21.863 ms`.
- During the user-run speedtest window, the UE remained registered and the DU showed heavy prior DRB traffic on LCID 4: roughly `33.3 MB` DL TX and `23.3 MB` UL RX on the default DRB at the start of the captured log.
- In that speedtest window, DL MCS was still pinned at `MCS (1) 0`. BLER moved from about `0.059` down through `0.00149`, with one spike to about `0.101`, while `dlsch_errors` stayed `0`.
- The same speedtest window showed substantial DU-to-CU latency under load: min/avg/max/mdev `202.840/356.892/602.300/120.030 ms` with `0%` ICMP loss.
- Link counter deltas over the roughly 65-second collection window showed about `27.0 MB` transmitted on the firecell GRE path and about `26.2 MB` received on the minipc GRE path, approximately `3.2-3.3 Mb/s` over that path during the window. The minipc Ethernet transmit delta was about `23.2 MB`, approximately `2.9 Mb/s`.
- In a later monolithic speedtest capture on `serber-firecell`, the active UE's
  DRB/LCID 4 DL counter reached about `966 MB` by the end of the captured
  window. Interface counters on the core bridge moved by roughly `1.0 GB` in
  each direction during the same window.
- The monolithic run showed DL MCS adaptation under load: the active UE reached
  a peak observed DL MCS of `23`, with sustained samples mostly around
  `18-21`. Representative active samples included `MCS (1) 19`, multiple
  `MCS (1) 21` samples, and later steady `MCS (1) 18-20` samples.
- The monolithic run's active BLER generally tracked around the OAI target
  region rather than decaying to zero while MCS stayed pinned: representative
  BLER samples at MCS `18-21` were roughly `0.08-0.14`.

Relevant OAI code observations:

- `init_bler_stats()` initializes `bler_stats->mcs` to `bler_options->min_mcs`.
- `dl_min_mcs` defaults to `0` in `MACRLC_nr_paramdef.h`.
- DL scheduling uses `get_mcs_from_bler()` and caps with `sched_ctrl->dl_max_mcs`.
- `get_mcs_from_bler()` only increments MCS when BLER is below the lower target and more than three new DL schedules occurred in the update window. It decrements on high BLER or too little activity.
- CQI/SINR reports update `sched_ctrl->dl_max_mcs`, but this run produced no UE CQI/SINR evidence.

## UE Registration And PDU Session Outcome

The first measurement window had no UE registered. After the phone was toggled
back onto the cell, the UE registered and the RAN/core completed PDU Session
Resource Setup for both `oai` and `ims`.

Before the runtime core config change, AMF logs showed the UE could register but
PDU session creation failed at SMF selection: the AMF reported that no SMF
candidate was available. After disabling AMF SMF selection in the runtime config
and restarting the Ethernet baseline, the AMF selected the SMF URI, SMF created
contexts, and SMF/UPF logs showed N4 session establishment/modification.

## SIB8/PWS Outcome

SIB8/PWS configuration reached the DU. UE observation was not possible because no UE registered during the window.

## Throughput Result

No user-plane throughput result was produced in this pass. The active UE window
does prove DRB/LCID traffic counters and active PDU sessions, but no controlled
downlink throughput run was executed.

The later user-run speedtest window produced measurable user-plane load, but
only as inferred from interface and DRB counters; the handset speedtest value was
not recorded in this sanitized report. The network-side counters show low
single-digit Mb/s movement and high DU-to-CU latency during the load.

The monolithic speedtest comparison produced the missing contrast: the same UE
class and radio can run with OAI DL MCS in the high teens/low twenties under
load. Therefore the split-mode `MCS 0` behavior is not a handset-wide or RF-only
limit.

## Comparison To Baseline

The Ethernet F1 rollback path was restored after route cleanup, and the core-side
PDU session failure was cleared in runtime evidence. The throughput baseline was
not remeasured with controlled traffic, so this run does not prove or disprove
the `19-23 Mb/s` baseline.

## Conclusion

The first immediate failure was not MCS: stale Quectel routes prevented Ethernet
F1 from establishing. After cleanup, Ethernet F1 established correctly.

The "PWS only, no 5G data" symptom was core-side. The UE could receive PWS and
register, but AMF PDU session creation failed while selecting an SMF. Changing
the runtime AMF setting to bypass SMF selection restored PDU session setup in
the observed logs.

For the MCS question, the active UE evidence shows that DL can remain at
`MCS (1) 0` while BLER is effectively zero and DRB counters exist historically.
That makes "no UE" and "no PDU session" insufficient explanations for all of
the observed low-MCS symptoms. However, the retained split speedtest log tail
does not prove the MCS decision state during the main downlink burst: LCID 4 DL
bytes were nearly flat in the saved samples, so the captured `MCS 0` lines may
be post-burst or low-activity scheduler state.

The remaining likely causes to test are scheduler state/feedback path behavior:
`bler_stats->mcs` starts at `dl_min_mcs = 0`, the update path may not be seeing
the successful DL scheduling window needed to increment, or the CQI/SINR-derived
`dl_max_mcs`/feedback path is not permitting escalation. The DU host's recurring
latency spikes are also now directly visible under speedtest load, with hundreds
of milliseconds of DU-to-CU ping latency. That may degrade F1/user-plane behavior
and throughput. The next controlled test should directly instrument CQI, HARQ
ACK accounting, `num_dl_sched`, and the selected `dl_max_mcs` while sustained
downlink traffic is actively running.

The monolithic comparison narrows the next split-mode debug target: inspect why
the split DU's DL adaptation path never reaches the same `18-23` MCS range. In
particular, compare split versus monolithic values for CQI/SINR-derived
`dl_max_mcs`, HARQ ACK/NACK accounting, `num_dl_sched`, and the selected MCS
before and after `get_mcs_from_bler()`.

## Follow-Up Analysis: 2026-06-03

The exact OAI scheduler files for the next debug pass are:

- `openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_dlsch.c`: DL MCS selection before
  PDSCH TBS calculation.
- `openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_primitives.c`:
  `get_mcs_from_bler()` and BLER/MCS state initialization.
- `openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_uci.c`: CQI/SINR updates to
  `sched_ctrl->dl_max_mcs`.

Runtime provenance remains mixed and should be treated carefully. CU and
monolithic logs reported running build hash `102965a669`, but the split CU
source tree HEAD readback was `9e67011af10f73264356366a59df7545349d9dab`.
The split DU host was not reachable over SSH during this follow-up, so its
source HEAD and patch apply status could not be rechecked.

The retained split log tail does not actually show a sustained downlink DRB
burst during the captured scheduler samples. In
`experiments/20260602_185129_split_performance_window/logs/du-filtered.log`,
LCID 4 DL TX moved only about `2.3 KB` across the retained samples, while
`dlsch_rounds[0]` moved by `66` and MCS stayed `0`. By contrast, the monolithic
window shows about `966 MB` LCID 4 DL TX movement and MCS up to `23`.

That means the current sanitized split evidence proves that MCS remained `0`
while the UE context existed and historical DRB counters were nonzero, but it
does not prove the exact MCS decision state during the main downlink burst. The
collector previously saved the last matching log lines after the window, which
can bias evidence toward post-burst idle/control traffic.

Another important transport clue is that the 18:51 split window showed traffic
on `test-gre@wlp3s0` and DU-to-CU ping around
`202.840/356.892/602.300/120.030 ms`, so that run was not a clean low-latency
Ethernet-F1 rollback measurement. This can starve or clump DU scheduling windows
and is consistent with low `num_dl_sched` in the retained samples.

Added temporary instrumentation patch:

```text
patches/performance/oai-dl-mcs-debug-instrumentation.patch
```

The patch applies cleanly to the monolithic expected base commit
`102965a669b9444857c27843ec8ce62780bf9d37` and logs `MCSDBG` lines for UE init,
CQI/SINR-derived `dl_max_mcs`, and the DL MCS decision path. It was not applied
to the deployed DU in this follow-up because `10.76.170.100` SSH timed out.

The collector was also tightened to record OAI log line numbers at the start of
the measurement window and filter from those offsets afterward, instead of using
only a post-window tail. The next split run should therefore capture the actual
speedtest interval more reliably.

## Rollback Procedure

Use Ethernet rollback startup after removing stale Quectel routes:

```sh
./scripts/oai-lab-tui --start-ethernet
```

The rollback helper now also deletes stale Quectel routes before checking management connectivity.

## Next Action

Register the Nothing Phone, generate sustained downlink traffic, then rerun:

```sh
./scripts/collect-split-performance-window.sh 60
```

The next window must include UE scheduler stats showing `dlsch_rounds`, `pucch0_DTX`, BLER, MCS, CQI/SINR if present, and throughput. Then test a forced variant with `dl_min_mcs = 10` only after recording the untuned baseline.

For the MCS-specific follow-up, add temporary scheduler logging around
`get_mcs_from_bler()` for the active UE: current MCS, candidate MCS,
`num_dl_sched`, BLER estimate, lower/upper BLER thresholds, `dl_max_mcs`, and
whether CQI/SINR reports updated the cap. Run that under sustained downlink
traffic before trying forced-MCS tuning.

## Follow-Up Attempt: 2026-06-03 Later

Attempted to restore the Ethernet CU/DU rollback baseline with:

```sh
./scripts/oai-lab-tui --start-ethernet
```

The launcher first stopped the running monolithic `nr-softmodem` on
`serber-firecell` and stopped the monolithic core containers. It then blocked
startup before launching the split CU/DU because `serber-minipc` did not detect
the USRP B210. `uhd_find_devices` returned no UHD devices, and `lsusb` did not
show an Ettus/USRP/B210/National Instruments device. Therefore no split DU was
started and no active downlink MCS measurement was collected in this attempt.

The DU-to-CU management path itself was clean Ethernet during the check:
`ip route get 10.76.170.38` on `serber-minipc` selected `enp2s0`, and a short
ping showed `0%` loss with a mostly low-latency path but one visible spike.

Patch application was not performed. The documented split DU path on
`serber-minipc`, `/home/serber/cu-du/source/openairinterface5g`, currently
contains only deployment/config files plus a `cmake_targets` symlink into the
monolithic OAI tree; it does not contain the scheduler source files targeted by
`patches/performance/oai-dl-mcs-debug-instrumentation.patch`. Applying the patch
there would either fail or modify the monolithic source/build path instead of an
isolated split-DU source tree, which violates the split-DU-only instrumentation
scope.

Next operator action is to reconnect or pass through the B210 to
`serber-minipc`, then restore a real split DU source tree at the documented path
or update the documented path to the actual isolated split DU source before
applying instrumentation.
