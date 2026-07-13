# Jetson B210 New Cable Full Test

Date: 2026-07-12

## Goal

Validate whether the newly installed USRP B210 cable on the Jetson Orin Nano
improves the previous Jetson Ethernet CU/DU throughput, overflow, BLER, and RTT
behavior.

## Live Topology

- DU/access host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- Radio: USRP B210 serial `8002816`
- Jetson DU ID: `0xe02`
- Access cell target: 106 PRB
- Expected F1 path: Ethernet between Jetson `10.76.170.8` and CU/core
  `10.76.170.38`
- Expected F1-U ports: UDP `2153` on both CU and DU

## Attempted Run

Command:

```bash
printf '\n' | ./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
```

TUI evidence directory:

```text
experiments/20260712_160639_ethernet_cu_du_rollback_start
```

## Sanitized Evidence

Observed at about 19:06 Asia/Riyadh:

- Jetson host discovery succeeded as `serber-jetson`.
- CU/core host discovery succeeded as `serber-firecell`.
- Jetson power and host tuning were already in the intended high-performance
  state:
  - `MAXN_SUPER`
  - CPU governors: `performance`
  - `usbfs_memory_mb = 1000`
  - high socket buffers
  - RT runtime disabled
- Jetson F1 network path was still the integrated Ethernet interface:
  - `enP8p1s0`
  - address `10.76.170.8/25`
  - negotiated speed `1000Mb/s`
- The CU/core interface remained:
  - `enp6s0`
  - address `10.76.170.38/25`
- The USRP B210 was visible by UHD and by serial `8002816`.
- After UHD firmware/probe activity, the B210 still remained on the USB 2.0
  tree:
  - Bus 001
  - device ID `2500:0020`
  - speed `480M`
- The USB 3 root and hub were present at `10000M`, but the B210 was not attached
  to that SuperSpeed path.
- The TUI stopped before launching OAI because Jetson B210 high-rate tuning did
  not confirm both `usbfs_memory_mb=1000` and SuperSpeed USB.
- No fresh CU/DU runtime, PWS, attach, PDU session, external-DN ping, or phone
  throughput measurement was valid from this attempt because the run did not
  pass radio transport preflight.

## Result

The new cable/path did not pass the minimum hardware gate in this run. The B210
was detected, but it stayed at USB High-Speed `480M` instead of SuperSpeed
`5000M`. This is worse than the previous validated Jetson run, where the B210
remained at `5000M` but throughput was still only about `6.5-7.3 Mbps`.

Because the B210 was stuck at `480M`, the full 106 PRB Jetson Ethernet CU/DU
test was intentionally not completed. Any throughput or BLER comparison from
this cable state would be invalid.

## Comparison Against Previous Jetson Result

Previous Jetson cable/hub state:

- B210 remained on USB SuperSpeed `5000M`.
- Phone-visible internet worked.
- Phone throughput was about `6.5 Mbps`, then about `7.3 Mbps`.
- External-DN ping eventually reached `0%` loss, but RTT was unstable.
- DU overflow count rose to about `23`.
- Active F1 path was still integrated Jetson `enP8p1s0` at `1000Mb/s`.

Current new-cable attempt:

- B210 remained at USB High-Speed `480M`.
- OAI launch was blocked by preflight.
- No phone-visible or network-side service gates were reached.
- No new throughput, BLER, MCS, or overflow comparison can be credited.

Interpretation:

The currently installed cable/path does not solve the Jetson throughput problem.
It fails earlier than the previous `5000M` state. The immediate blocker is the
physical USB3 path for the B210, not F1, SMF, PDU session routing, or phone APN.

## Next Action

Physically reseat or replace the B210 cable/path before rerunning OAI:

1. Connect the B210 with a known USB3-capable cable directly into the Jetson USB3
   path, or into the known-good SuperSpeed hub port.
2. Avoid USB2-only extension cables, adapters, or hub ports.
3. Confirm `lsusb -t` shows the B210 under the USB3 tree at `5000M` after
   `uhd_find_devices --args serial=8002816`.
4. Rerun:

```bash
printf '\n' | ./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
```

5. Only after the B210 is at `5000M`, continue with PWS, attach, PDU session,
   external-DN ping, phone internet, speed test, overflow, BLER, and MCS
   validation.

