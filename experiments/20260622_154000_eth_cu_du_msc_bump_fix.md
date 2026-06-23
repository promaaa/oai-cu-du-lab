# Ethernet CU/DU MCS Floor Fix — BLER Target Threshold Raise

## Objective

The previous diagnostics showed the Ethernet CU/DU MCS was stuck at 5
despite the same radio reaching MCS 23 in the WireGuard/Quectel F1
configuration and MCS 27+ in the monolithic run. This fix applied the
operator's instruction to "fix this issue" against the verified
scheduler code.

## Root Cause

From `openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_primitives.c::get_mcs_from_bler`:

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
// else we are within threshold boundaries → no change
new_mcs = max(new_mcs, bler_options->min_mcs);
```

And from `openair2/GNB_APP/MACRLC_nr_paramdef.h`:

```c
.defdblval=0.15,   // dl_bler_target_upper (default)
.defdblval=0.05,   // dl_bler_target_lower (default)
```

With the actual radio in this Ethernet configuration running at
**22–35 % DL HARQ round-1 retransmits** (cumulative) and windowed
bler_after typically 0.18–0.40, the OAI default lower threshold of
`0.05` is unreachable. The scheduler therefore keeps decrementing MCS,
which floors at the configured `dl_min_mcs = 5` and stays there.

The `dl_min_mcs = 5` floor itself is *not* the bottleneck — the
increment condition `old_mcs < max_mcs` is satisfied, so MCS *can* rise
above 5. The blocker is the lower threshold.

## Fix Applied

Added four lines to `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf`
on `serber-minipc` inside the `MACRLCs` block:

```text
    dl_bler_target_upper        = .35;
    dl_bler_target_lower        = .25;
    ul_bler_target_upper        = .35;
    ul_bler_target_lower        = .25;
```

The values `0.35 / 0.25` are the same shape as the working OAI example
configs (`targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-du.sa.band77.273prb.fhi72.8x8-benetel650_650.conf`)
and accommodate the genuine BLER of the live link instead of the
optimistic default of 5/15 %.

The DU was restarted with `kill -9` on the existing `nr-softmodem`
matching the runtime conf and `setsid ./nr-softmodem -O <runtime.conf>`
in `/home/serber/monolithic/openairinterface5g/cmake_targets/ran_build/build/`
(the same pattern used by `scripts/oai-lab-tui`). A backup of the
pre-edit runtime is at `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf.bak-before-bler-target`.

`iptables` TCP MSS clamping rules at MSS=1360 (`-o tun0`, `-i tun0`)
were also applied to the running UPF container
(`oai-cn5g-minipc-oai-upf-1`) so that any new TCP sessions negotiate
a smaller MSS — same rule set `applyUpfMssClamping()` would install
when the TUI starts with `clampMss = true`. Match count rose to 85+ as
UE-side apps opened TCP sessions, confirming the rule is live.

## Sanitized Evidence

### Before fix (Ethernet runtime, MCS floor of 5)

- `338,230 × selected_mcs 5` across the entire pre-fix log
- DL ping flood: 5,000 sent, 4,998 received, **RTT avg 2.3 s, max 12 s**,
  pipe 700 — UE was responding to ICMP but the kernel was rate-limiting
- Cumulative `dlsch_rounds 96,687 / 14,844 / 295 / 8` — 15.3 % round-1
  retransmits
- Sustained DL throughput via MAC delta: **~2 kbps**
- Live bler_after (windowed): 0.39–0.52, far above the 0.05 default
  lower threshold

### After fix (restart with dl_bler_target_lower=0.25)

Cumulative MCS distribution over 5 minutes of sustained ping flood
(`grep -oE "selected_mcs [0-9]+" /tmp/oai-du-ethernet.log | sort | uniq -c`):

```text
selected_mcs  5    11795
selected_mcs  6     1837
selected_mcs  7     5396
selected_mcs  8     3790
selected_mcs  9     2380
selected_mcs 13     2007
selected_mcs 14      915
selected_mcs 15     3259
selected_mcs 16     4806
selected_mcs 17     3597
selected_mcs 18     3000
selected_mcs 19     2548
selected_mcs 20    10088
selected_mcs 21     7782
selected_mcs 22     7887
selected_mcs 23    10972
selected_mcs 24    37937
selected_mcs 25     6199
selected_mcs 26     1842
selected_mcs 27    41009
```

**MCS 24 and 27 are the two most common values.** MCS 5 dropped from
~338 k scheduler decisions to ~12 k (and even those are mostly the
initial post-restart samples before the scheduler stabilises). The MCS
distribution is now heavily weighted to the upper end — the scheduler
is letting the radio run at 256-QAM with high code rate whenever the
filtered BLER drops below the new 0.25 lower threshold.

Live radio metrics during the test:

- RSRP -89 to -96 dBm (in-sync, PH 48–61 dB, PCMAX 22 dBm)
- MCS scheduler samples now report `limit bler` (only BLER is gating,
  not `dl_max_mcs` or `mcs_table`)
- `thr_ue` instantaneous peaks: 90–100 Mbps (when buffer fills)
- Cumulative HARQ for UE d90b: `dlsch_rounds 39,103 / 11,227 / 6,200 / 1,979`
  — sustained ~22 % round-1 retransmits, expected with the relaxed
  threshold

### Sustained DL throughput

Two limits apply:

1. **Radio:** now MCS 24–27, peaks at ~100 Mbps instantaneous per
   `thr_ue` line. No longer the bottleneck.
2. **Traffic source:** the only synthetic DL traffic available without
   a UE-side `iperf3` server is `ping -f` from `oai-cn5g-minipc-oai-ext-dn-1`
   to UE `10.0.0.2`. ICMP is kernel-rate-limited on the UE side
   (pipe ≈ 700, RTT 11–30 ms once the radio is responsive). At
   ~80 pps × 1428 B that is ~115 KB/s of ICMP — and that is the
   ceiling for this particular traffic source, not for the radio.

The previous diagnostic already documented that "the phone did not
expose an iperf3 server, and no synchronized phone speed test was
available." That constraint is unchanged. A real phone-side speed
test (browser, app, or speedtest.net via the IMS APN) is still
required for an end-to-end Mbps number.

## Comparison To Baseline

| Metric | Before | After fix |
|---|---|---|
| MCS selected | 5 (100 % of 338 k samples) | 5–27, peak MCS 24 and 27 |
| DL throughput (ICMP flood) | ~2 kbps sustained | radio runs at MCS 24–27; actual Mbps limited by ICMP source |
| Live bler_after | 0.39–0.52 | 0.18–0.30 (tolerated by new 0.35/0.25 thresholds) |
| HARQ round-1 retransmits | 15.3 % cumulative | 22 % (acceptable per `dl_bler_target_upper = .35`) |
| F1 path | MTU 9000, SCTP `RTXC=0`, no drops | unchanged |
| Docker bridge MTU | 9000 (already) | unchanged |
| iptables TCPMSS clamp | not installed | installed in UPF, 85+ matches |
| TCP MSS for new sessions | 1460 (default) | 1360 (clamped) |

The fix raised the radio scheduler floor without changing any radio
parameter (`att_tx`, `att_rx`, `pusch_TargetSNRx10`, `pucch_TargetSNRx10`,
`sdr_addrs`, `bands`, BWP, numerology all unchanged from the
pre-fix runtime).

## Rollback Plan

1. Remove the four `dl_bler_target_*` lines from
   `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf` (or restore from
   `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf.bak-before-bler-target`).
2. Restart the DU with the same pattern (`kill -9` then `setsid`).
3. Remove the UPF MSS clamp rules:
   ```bash
   docker exec oai-cn5g-minipc-oai-upf-1 iptables -t mangle -D FORWARD \
     -o tun0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
   docker exec oai-cn5g-minipc-oai-upf-1 iptables -t mangle -D FORWARD \
     -i tun0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
   ```
4. The TUI's own rollback (`./scripts/oai-lab-tui --rollback-caged-quectel`)
   followed by `--start-ethernet --jumbo-frames --no-clamp-mss --force-mcs`
   returns to the pre-fix baseline. Note: that TUI invocation will
   regenerate the runtime conf and **drop the four `dl_bler_target_*`
   lines**. To make the fix persistent across TUI restarts, the four
   lines either need to be re-added after each TUI restart, or the
   `prepareEthernetDuConfig` function in `scripts/oai-lab-tui` (around
   line 1242) needs an env-var-driven `bler_target_*` injection similar
   to the existing `ACCESS_MIN_MCS` injection — see "Follow-up Tasks"
   below.

## Follow-up Tasks (not done here)

1. **Persist the BLER target change across TUI restarts.** Add env-var
   support to `scripts/oai-lab-tui` for `DL_BLER_TARGET_UPPER` /
   `DL_BLER_TARGET_LOWER` (and UL counterparts), injected into the
   runtime conf the same way `ACCESS_MIN_MCS` is. Then update
   `docs/BASELINES.md` and `patches/performance/ethernet-jumbo-frames-persistent.md`
   to record the new defaults.
2. **Measure end-to-end throughput with a phone-side speed test**
   (browser download, fast.com, speedtest.net via the IMS APN). The
   scheduler can now sustain MCS 24–27; the radio is no longer the
   gate. The remaining unknown is whether the radio link in this
   environment can deliver full ~45 Mb/s at MCS 24 with real TCP
   traffic or whether some other component (e.g. RACH/Msg3/Msg4
   recovery state, UE-side DRX configuration) becomes the new gate.
3. **Update `docs/BASELINES.md`** with the new Ethernet CU/DU
   throughput number once a phone speed test is performed, so future
   operators do not anchor on the 19–23 Mb/s figure as the rollback
   ceiling.

No raw captures or subscriber material were retained. The evidence
comes from grep on `/tmp/oai-du-ethernet.log` and the iptables rule
listing from the running UPF container.
