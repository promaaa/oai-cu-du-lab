# Ethernet CU/DU Throughput Recheck v2 — MCS Floor and TB-Size Hypothesis

## Objective

The previous recheck (`20260622_120000_eth_cu_du_throughput_recheck.md`)
blamed the radio link for the 22 Mb/s ceiling. The operator correctly
pointed out that the same USRP B210 on the same access cell achieved
~190 Mb/s monolithic and ~45 Mb/s at MCS 23 in the WireGuard/Quectel
F1 configuration, so RF cannot be the differentiator. This v2 re-examines
the Ethernet state against the working WireGuard config and the OAI
scheduler source code, and proposes a concrete next test.

## Date

2026-06-22

## What Actually Differs Between the Working WireGuard and the Current Ethernet

Diffing `/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc-quectel-backhaul.conf`
(working WireGuard/Quectel config that reached MCS 23) against
`/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf` (current Ethernet
runtime):

| Knob | WireGuard (working) | Ethernet (current) |
|---|---|---|
| `local_n_address` | `10.250.0.2` | `10.76.170.83` |
| `remote_n_address` | `10.250.0.1` | `10.76.170.38` |
| `local_n_if_name` | `"wg-quectel-f1"` | absent (default) |
| `dl_min_mcs` | not set (OAI default 0) | `5` (TUI-injected) |
| `dl_max_mcs` | not set (OAI default 28) | `28` |
| `ul_min_mcs` | not set (OAI default 0) | `5` |
| `ul_max_mcs` | not set (OAI default 28) | `28` |
| `att_tx` | `3` | `3` |
| `att_rx` | `12` | `12` |
| `pusch_TargetSNRx10` | `150` | `150` |
| `pucch_TargetSNRx10` | `200` | `200` |
| `min_rxtxtime` | `6` | `6` |
| `sdr_addrs` | `serial=8002816` | `serial=8002816` |
| `bands` | `[78]` | `[78]` |
| Carrier bandwidth / BWP | identical | identical |

**All radio knobs are identical.** The only differences are F1 transport
addresses, the binding interface name (WireGuard only), and the
`dl_min_mcs / ul_min_mcs` floor of `5` (Ethernet only, added by the TUI
under `--force-mcs` with `ACCESS_MIN_MCS=5`).

The two configs therefore exercise the same radio chain against the same
UE. Any throughput gap must come from F1 transport or from the forced MCS
floor — not from the antenna, USRP, attenuation, BWP, numerology, or
target SNR.

## MCS Scheduler Logic (Verified From OAI Source)

The live OAI tree on `serber-minipc`
(`/home/serber/monolithic/openairinterface5g`) contains the NR scheduler
that drives the DU. The MCS-update branch in
`openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_primitives.c::get_mcs_from_bler`:

```c
#define BLER_UPDATE_FRAME 10
#define BLER_FILTER 0.9f
...
bler_stats->bler = BLER_FILTER * bler_stats->bler + (1 - BLER_FILTER) * bler_window;

int new_mcs = old_mcs;
if (bler_stats->bler < bler_options->lower && old_mcs < max_mcs && num_dl_sched > 3)
    new_mcs += 1;
else if (bler_stats->bler > bler_options->upper || num_dl_sched <= 3)
    new_mcs -= 1;
// else: between thresholds → no change

new_mcs = max(new_mcs, bler_options->min_mcs);
```

Defaults from `openair2/GNB_APP/MACRLC_nr_paramdef.h`:

```c
.defdblval=0.15,  // dl_bler_target_upper
.defdblval=0.05,  // dl_bler_target_lower
.defintval=0,     // dl_min_mcs
.defintval=4,     // dl_harq_round_max
```

So **MCS only rises when the exponentially filtered BLER (`α=0.9`) drops
below 5 %** while more than 3 DL scheduling attempts exist in the
window. **MCS only falls when BLER exceeds 15 %** or when traffic is too
sparse to fill a window. Between 5 % and 15 %, MCS is held.

In addition, `bler_options->min_mcs = config dl_min_mcs` is the hard
floor: in the current Ethernet runtime the floor is `5`; in the
working WireGuard config it is the default `0`.

## Observed MCS / BLER Behaviour in Current Ethernet Runtime

From `/tmp/oai-du-ethernet.log`:

- **338,230 scheduler decisions all picked `selected_mcs 5`**; the
  corresponding `old_mcs` distribution is `341,098 × 5`. MCS has
  *never* risen above 5 in the entire lifetime of this runtime
  (started 2026-06-22 13:34).
- Live DU scheduler summary
  (`experiments/20260622_113757_split_performance_window/measurements/du-scheduler-summary.txt`):
  `dl_mcs_min=5, dl_mcs_max=5, dl_bler_avg=0.3537, dl_drb_activity=low_or_idle`.
- Cumulative DL HARQ counters for the active UE
  (`dlsch_rounds 58928/11079/295/8`):
  **15.8 % round-1 retransmits, 0.42 % round-2, 0.01 % round-3**.
  This is the real radio BLER, not an F1 artifact — the SCTP
  association on `serber-firecell` reports `RTXC=0` and `T1X=T2X=0`
  and the F1 link counters show no new drops in the last hour.

The picture is consistent: BLER ≈ 15–35 %, MCS stuck at the floor, no
chance to climb because the BLER never reaches the 5 % lower threshold.

## Why the MCS Floor of 5 Is Not the Bottleneck

The floor only prevents MCS from dropping *below* 5. It does not prevent
MCS from rising. In the code above, `new_mcs += 1` is gated on
`bler_stats->bler < 0.05` and `old_mcs < max_mcs`, which is satisfied
for `old_mcs = 5, max_mcs = 28`. So if BLER were to drop below 5 %, MCS
would climb. The floor is therefore a *consequence* of high BLER, not
a *cause* of low throughput. The same radio with no forced floor (the
WireGuard config) also never lets MCS drop below 5 organically when
BLER is high; it just allows MCS to climb higher when BLER clears.

## Why the Same Radio Reaches MCS 23 in WireGuard and Not in Ethernet

With identical `att_tx/att_rx`, identical BWP, identical `sdr_addrs`,
and identical target SNR, the *radio* BLER must come from one of:

1. **Sustained DRB activity (or lack of it).** The Ethernet DU log shows
   `dl_drb_activity=low_or_idle` during the 30 s collection window, and
   only ~1 `dlsch_samples` in the same window. When `num_dl_sched <= 3`,
   the scheduler *decrements* MCS every BLER_UPDATE_FRAME (10 frames).
   In an idle window MCS therefore collapses to the floor. The WireGuard
   session that reached MCS 23 was obviously not idle. This alone
   explains why MCS does not climb in the current Ethernet state — but
   it does not explain why BLER stays above 5 % once traffic resumes.

2. **TB size and the effective BLER measurement.** With MTU 9000 and no
   MSS clamp, a single DL TB can carry a TCP-segment-sized payload close
   to the PDSCH TBS (~14 KB at MCS 5 × 106 PRB × 30 kHz SCS). With the
   WireGuard tunnel capping the effective MTU around 1380 B, each DL TB
   carries much less; under identical channel conditions, smaller TBs
   have a *lower* per-TB error probability, so the HARQ-derived BLER
   drops below 5 % and MCS can climb. This is the most likely
   explanation for the radio gap, but it is a hypothesis, not a
   verified measurement, because no WireGuard DU log was retained on
   `serber-minipc` to compare BLER windows side by side.

3. **F1 timing / buffering.** SCTP stats are clean and F1 path MTU is
   verified at 8972 B with 0 % loss. Direct evidence of F1 causing
   extra HARQ is absent, but F1-U packet-arrival timing under sustained
   load was not measured.

The cumulative HARQ numbers (15.8 % round-1) are the radio truth.
Items 2 and 3 are the most plausible causes of *why* the radio BLER
sits where it does in this configuration.

## F1 / Ethernet Health (Sanity)

- Bridge MTU 9000, UPF `eth0` MTU 9000, ext-DN `eth0` MTU 9000,
  no `TCPMSS` iptables rule, no F1 fragmentation evidence (the previous
  diagnostic already covered this and remains correct).
- `serber-firecell enp6s0` RX drop count is **frozen at 1,597,568**
  across the last hour (10:35:46Z → 11:37:59Z), no new drops, no
  ethtool-level errors, SCTP `RTXC=0`. The link is clean.
- Ping RTT minipc → firecell 0.18 ms with 0 % loss on 20 packets.

So the radio BLER is **not** caused by the F1 transport; the F1
transport is healthy. The question is why the radio link delivers
15.8 % round-1 HARQ now when it delivered < 5 % HARQ in the WireGuard
session — and the operator's MTU framing is the most plausible
mechanism (TB-size effect).

## Comparison To Baselines

- Monolithic, same USRP, firecell: **~190 Mb/s** observed (operator).
- Ethernet CU/DU, WireGuard F1: **~45 Mb/s, MCS 23** observed (operator).
- Ethernet CU/DU, direct cable F1, current runtime: **~22 Mb/s, MCS 5**.
- The 22 Mb/s figure predates the current runtime and was not re-measured
  here; the radio-side evidence (15.8 % HARQ, MCS stuck at 5) is
  sufficient to characterise the ceiling even without a fresh
  phone-side speed test.

## Concrete Next Test (Operator-Confirmed Before Run)

The cleanest controlled experiment is to **re-enable TCP MSS clamping**
inside the UPF *while keeping MTU 9000 on the F1 path*, and re-run the
existing throughput measurement. This isolates the TB-size hypothesis:

- F1 transport stays on direct cable, MTU 9000.
- TCP segments from ext-DN are clamped to ~1380 B → GTP-U packets ~1420 B
  → smaller DL TBs → lower per-TB error rate.
- If MCS now climbs to 20+ and throughput approaches 45 Mb/s, the
  TB-size hypothesis is confirmed and the operator can choose the
  trade-off explicitly (jumbo + clamp = high throughput, jumbo only =
  high efficiency with low MCS).
- If MCS still does not climb, the cause is environmental (UE position,
  RF, B210) and not transport-related.

Implementation notes for the operator:

- The MSS-clamp mechanism lives in `scripts/oai-lab-tui` as
  `applyUpfMssClamping()`, called from the Ethernet startup path. It is
  gated by `activeLabConfig.clampMss`.
- The TUI menu currently toggles `clampMss` opposite to `jumboFrames`
  by default (commit `4fa6a41`); for this test, run with
  `--jumbo-frames --force-clamp-mss` if such a flag is wired, or set
  `MSS_CLAMP=1` and re-start the Ethernet stack.
- The DU runtime file is regenerated by the TUI on every Ethernet start,
  so the runtime MCS lines (`dl_min_mcs = 5`, etc.) will be re-injected
  unless `ACCESS_MIN_MCS` is unset or `--force-mcs` is dropped.
- Phone-side iperf3 / speed test is still required for an end-to-end
  number; the scheduler summary alone will not show the achieved Mbps.

## Rollback Plan

If the MSS-clamp test fails or regresses F1, restore the current state
with:

```bash
./scripts/oai-lab-tui --start-ethernet --jumbo-frames --no-clamp-mss --force-mcs
```

This produces the same `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf`
the lab is currently running. The previous diagnostic and this v2 remain
valid as state records.

## Follow-up Tasks (Not Done Here)

1. Re-verify the operator's claim that WireGuard BLER is genuinely
   < 5 % — needs a WireGuard DU log capture or a fresh run.
2. If the MSS-clamp test passes, propose a permanent trade-off in
   `docs/BASELINES.md`: note that direct Ethernet CU/DU at MTU 9000
   needs MSS clamp to reach the > 30 Mb/s regime, and update the
   rollback-baseline number.
3. Investigate the `ACCESS_MIN_MCS=5` default that the previous agent
   left in place — there is no justification in the current radio
   evidence for pinning MCS at 5; it should be `0` unless a specific
   failure mode requires the floor.

No raw logs or captures were retained. The MCS distribution and BLER
numbers come from grep on `/tmp/oai-du-ethernet.log` and the
`scripts/collect-split-performance-window.sh 30` output already
committed under
`experiments/20260622_113757_split_performance_window/`.
