# Docker Bridge MTU Diagnostic

## Objective

Test whether the split-core Docker bridge at MTU 1500 fragments downlink GTP-U traffic and
causes the observed Ethernet CU/DU throughput ceiling.

## Date

2026-06-22

## Topology

- Core/CU: `serber-firecell`, direct F1 interface `enp6s0`, `10.76.170.38/25`
- DU/radio: `serber-minipc`, direct F1 interface `enp4s0`, `10.76.170.83/25`
- Direct F1 path: MTU 9000, 8972-byte DF probes passed with 0% loss
- Split core bridge: `oai-cn5g-minipc`

## Repository And OAI Revisions

- Control repository starting commit: `4fa6a41`
- Live CU and DU OAI trees: `9e67011af10f73264356366a59df7545349d9dab`
- The live revision differs from the documented rollback pin
  `102965a669b9444857c27843ec8ce62780bf9d37`; this run must not replace that baseline.

## Change

Added the following option to the external split-core Compose network and recreated the core:

```yaml
com.docker.network.driver.mtu: "9000"
```

The external deployment file was backed up to `/tmp` before editing. Rollback is to remove the
option, validate the Compose file, and recreate the core network.

## Sanitized Evidence

- Before: Docker bridge, UPF `eth0`, and external-DN `eth0` reported MTU 1500.
- A 200-packet, 1472-byte UE ping test passed with 0% loss and increased UPF
  `FragCreates` by 400.
- After: Docker bridge, UPF `eth0`, and external-DN `eth0` reported MTU 9000.
- All ten split-core containers became healthy.
- Controlled Ethernet restart restored F1 setup, DU radio sync, SIB8 configuration, both PDU
  sessions, and reachability of UE address `10.0.0.2`.
- The direct path passed three 8972-byte DF probes with 0% loss.
- A repeated 200-packet, 1472-byte UE ping test passed with 0% loss.
- Interface-filtered observation found no repeatable fragments sourced by the UPF on the
  downlink. It did find two UE-originated inner fragments per large echo reply. Aggregate UPF
  fragment counters therefore mix distinct directions and are not sufficient evidence that the
  Docker bridge fragments downlink GTP-U traffic.
- UPF `tun0` retained `fq_codel`; the former 1500 kbit/s shaper was absent.

No raw capture or subscriber material was retained.

## Throughput Result

Not measured. The phone did not expose an iperf3 server, and no synchronized phone speed test
was available during this window. No throughput improvement is claimed.

## Comparison To Baseline

The Ethernet rollback baseline remains 19-23 Mb/s. This run proves that the Docker network MTU
change can be deployed without losing F1, radio sync, PWS/SIB8 configuration, or UE reachability,
but it does not prove that Docker MTU was the 22 Mb/s bottleneck.

## Next Action

Run `scripts/collect-split-performance-window.sh 30` during a phone downlink speed test. Compare
throughput, DU BLER/MCS, UPF counters, and a direction-filtered fragment count over the same
timestamped window. If throughput remains below 30 Mb/s, prioritize RF quality and scheduler
evidence rather than further Ethernet MTU changes.

## Follow-up: DU Runtime Attenuation Fix

The first follow-up window showed downlink BLER around 43-50% while forced MCS 10 was active.
Disabling the floor exposed a separate launcher defect: its Perl replacement joined capture
group `$1` directly to attenuation values, so values `3` and `12` were parsed as capture groups
`$13` and `$112`. Both attenuation settings disappeared from the generated runtime config.

The launcher now uses evaluated replacements that preserve the setting name and value. A clean
Ethernet restart verified:

- `att_tx = 3`
- `att_rx = 12`
- no forced minimum MCS
- Docker bridge MTU 9000
- ten healthy core containers
- F1, radio sync, SIB8, and UE reachability

After correction, idle downlink BLER initially fell below 1%. The synchronized collection window
contained only low DRB activity, so a new phone speed-test value is still required.

The `3/12` attenuation run later entered repeated Msg4/RRC transactions and the CU asserted,
leaving PWS reception but no registered UE. A `0/0` rollback caused Msg3 HARQ failures. The
working recovery combined the successful directions:

- `att_tx = 0` for stronger downlink Msg4 delivery
- `att_rx = 12` for reliable uplink Msg3 reception
- forced minimum MCS 10 restored temporarily to match the prior service state

After one airplane-mode cycle, UE data reachability returned. Twenty consecutive core-to-UE
pings passed with 0% loss, the CU remained running, all ten core containers were healthy, and
both physical F1 interfaces plus the Docker bridge reported MTU 9000. Throughput tuning must
continue from this service-restored state without changing multiple RF controls at once.

An 18 Mb/s follow-up at forced MCS 10 showed roughly 40-50% downlink BLER while the DU host
remained about 58% idle and the Ethernet/UPF path showed no active shaper or link errors. Changing
TX attenuation from 0 to 3 dB did not materially change BLER, ruling out simple close-range
transmitter overdrive. The launcher now accepts `ACCESS_MIN_MCS`; a controlled MCS-5 run retained
UE data reachability. Its collection window contained no sustained DRB traffic, so the comparative
phone throughput result remains pending.
