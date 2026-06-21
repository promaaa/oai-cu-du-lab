# 20260621 — Ethernet CU/DU Split MCS Unlock — Four-Test Permutation

**Date:** 2026-06-21  
**Hosts:** serber-minipc (DU, B210), serber-firecell (CU/CN5G)  
**Backhaul:** 1 GbE Ethernet (canonical rollback baseline)  
**OAI commit:** 30ce3f72958eb15aa489ca4de6c4f3cd24e1871f  
**UE:** Commercial handset, single active RNTI per run

---

## Objective

Determine whether TCP MSS clamping and/or a forced DL MCS floor can unlock the Ethernet split
scheduler from its observed MCS 0–7 ceiling and improve DL throughput beyond the 12 Mbps baseline.

---

## Setup

- **MSS clamping:** `iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360`
  applied inside `oai-cn5g-minipc-oai-upf-1` container on serber-firecell when enabled.
- **Forced MCS:** `dl_min_mcs = 10; dl_max_mcs = 28; ul_min_mcs = 5; ul_max_mcs = 28; target_bler = 0.05;`
  injected into the runtime DU config on serber-minipc when enabled.
- **Measurement window:** 60 seconds per test, via `scripts/collect-split-performance-window.sh`.
- **Throughput computed** from LCID5 TX/RX byte delta in the DU scheduler log (remote SSH parse).

---

## Results

| Test | Config | DL (Mbps) | UL (Mbps) | MCS max | DL BLER avg |
|------|--------|-----------|-----------|---------|-------------|
| 1 | Untuned baseline | 12.07 | 0.09 | 7 | N/A |
| 2 | TCP MSS clamping only (1360 B) | 15.80 | 3.65 | 10 | 0.2634 |
| 3 | Forced MCS floor only (min=10) | ~0 | ~0 | 5 | N/A |
| 4 | MSS clamping + Forced MCS | 17.18 | 0.16 | 10 | 0.2297 |

Experiment directories: `20260621_095542_split_performance_window` (Test 1),
`20260621_102905_split_performance_window` (Test 2), `20260621_103453_split_performance_window` (Test 4).

---

## Key Observations

1. **TCP MSS clamping is necessary** to prevent GTP-U fragmentation; without it, forcing MCS ≥10
   causes near-zero throughput (Test 3) due to excessive retransmissions on fragmented packets.
2. **MSS clamping alone** raises MCS ceiling to 10 and improves DL by ~31% (+3.7 Mbps).
3. **Combined tuning** yields the best DL result (+42% vs. baseline) with a slightly reduced BLER.
4. **UL throughput** drops in Test 4 vs. Test 2 (0.16 vs. 3.65 Mbps), likely because symmetric
   MSS clamping affects UL GTP-U paths as well.
5. **F1 backhaul latency** was 0.07–0.52 ms RTT — not the limiting factor.
6. **Persistent LLLL underruns** on serber-minipc indicate real-time CPU pressure independent of
   the fragmentation issue.

---

## Rollback Baseline Confirmed

Test 1 (untuned Ethernet split, 12 Mbps DL) matches the documented rollback baseline in
`docs/BASELINES.md`. No regression was introduced.

---

## Sanitized Evidence

- Raw logs are **not** committed to Git. Experiment directories contain only byte-counter and
  scheduler summary text files (no personal data, no packet captures, no UE identifiers beyond
  temporary RNTIs).
- RNTIs logged are ephemeral radio identifiers, not persistent UE identities.

---

## Next Actions

1. Raise F1 Ethernet interface MTU to 9000 B (jumbo frames) to eliminate GTP-U fragmentation
   without application-layer MSS clamping — cleaner long-term fix.
2. Set CPU governor to `performance` on serber-minipc; evaluate `isolcpus` for OAI RT threads
   to resolve `LLLL` underruns.
3. Apply MSS clamping directionally (DL only) to recover UL throughput.
4. Proceed with wireless F1 backhaul via Quectel modem (next milestone per `audit/MIGRATION_MAP.md`).
