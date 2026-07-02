# Jetson Orin Nano DU integration and 106 PRB stabilization

**Date:** July 2, 2026
**Timeline:** April 7 to July 31, 2025 (16 weeks)

---

## What changed since last update

1. Jetson kernel support was completed: the Orin Nano now boots a custom SCTP-enabled kernel.
2. OAI was compiled natively on the Jetson: UHD and `nr-softmodem` were built locally within the board memory limits.
3. The Jetson was integrated into the lab TUI: new Jetson Ethernet and Jetson Quectel benchmark profiles were added.
4. F1AP association was validated: the Jetson DU reached the CU on `serber-firecell` and exchanged F1-C heartbeats.
5. The USB blocker was fixed: the B210 now runs through the Jetson USB-C path at USB 3.0 speed and the 106 PRB DU run stays stable in the current validation window.
6. The Jetson F1-U port mismatch was fixed: the DU runtime now listens on UDP `2153`, matching the CU F1-U path.
7. The Jetson DU-side SIB8/PWS patch was applied and rebuilt, so the DU now accepts the CU Write Replace Warning Request instead of ignoring F1AP procedure code `20`.
8. Lab-side user-plane validation now passes: the external DN can ping the live UE data IP `10.0.0.2` through bidirectional F1-U.

---

## Motivation

The Raspberry Pi 5 and MiniPC experiments showed that a lightweight host can run the OAI DU role with the USRP B210, but each platform has different limits. The Jetson Orin Nano was tested as a stronger embedded DU candidate because it provides more CPU headroom than the Raspberry Pi and could be useful for a portable or drone-carried access DU.

The target was to keep the same CU/core architecture on `serber-firecell` while moving the access DU and B210 to the Jetson.

---

## Kernel compilation challenges and multiple attempts

Enabling SCTP support on the Jetson Orin Nano required compiling a custom kernel. We encountered several major difficulties across multiple attempts before achieving a stable, coherent boot:

1. **BSP Source Matching Mismatches**: Initial compilation attempts using generic kernel sources failed because the Jetson Orin Nano DevKit requires the exact NVIDIA L4T BSP (Board Support Package) source code matching the running OS release (`R36.4.4` / JetPack 6.2). Using standard upstream or mismatched NVIDIA branches resulted in compilation failures or unresolved dependencies.
2. **Proprietary out-of-tree (OOT) module integration**: The Jetson BSP relies heavily on out-of-tree proprietary drivers (including `nvgpu`, display controller, audio, event loggers, etc.). Early attempts at compiling only the main kernel source led to a bootable kernel but a completely broken system state. The display manager crashed, and hardware acceleration (GPU) was unavailable because OOT modules were missing.
3. **Module Symbol & Version Conflicts**: The proprietary OOT modules must be compiled against the exact same kernel headers, configuration, and compiler version as the main kernel. Mismatched kernel versions or a missing `CONFIG_LOCALVERSION` configuration caused the modules to throw symbol mismatch errors (`-1 Invalid module format`) on boot, breaking core system drivers.
4. **Coherent Native Build Memory Bottlenecks**: Cross-compiling the entire L4T kernel and NVIDIA drivers on external hosts introduced toolchain mismatches. We resolved this by building natively on the Jetson board itself. However, compilation frequently crashed due to RAM exhaustion (8GB limit on the Jetson Orin Nano). This was resolved by creating a temporary swap space and constraining compiler parallelization (`make -j4`).
5. **Safe Dual-Boot Recovery Path**: To prevent bricking the board during unstable boot attempts, we had to configure a custom `initrd` and boot entry in `/boot/extlinux/extlinux.conf`. This allowed fallback booting into the default stock kernel using a serial console or external keyboard.

---

## Jetson configuration

| Component | Value |
| --- | --- |
| DU host | `serber-jetson` |
| Jetson management IP | `10.76.170.8` |
| CU/core host | `serber-firecell` |
| CU/core IP | `10.76.170.38` |
| Access radio | USRP B210 |
| B210 serial | `8002816` |
| OAI commit | `102965a669b9444857c27843ec8ce62780bf9d37` |
| Jetson kernel | `5.15.148-tegra-oai-sctp-tegra-oai-sctp` |
| DU ID | `0xe02` |
| Access bandwidth tested | 106 PRB |
| OAI sample-rate mode | `-E`, 46.08 MSps |

The Jetson DU runtime configuration uses the normal Ethernet F1 path:

```yaml
f1_transport:
  du_local_address: 10.76.170.8
  cu_remote_address: 10.76.170.38
  f1_u_udp_port: 2153
  mode: Ethernet

radio:
  device: USRP B210
  serial: 8002816
  prb: 106
  sample_rate: 46.08 MSps
  du_id: 0xe02
```

---

## What worked

The kernel and software bring-up were successful. The Jetson now boots with SCTP support enabled and can create SCTP sockets. This removed the first blocker for running the OAI DU role.

UHD was compiled and installed on the Jetson, and the B210 can be discovered by UHD when it is not already owned by the softmodem. OAI was also compiled natively on the Jetson with reduced parallelism to stay within memory limits.

The TUI now includes Jetson launch paths:

```yaml
tui_profiles:
  jetson_ethernet: ./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
  jetson_quectel: ./scripts/oai-lab-tui --jetson-quectel --start-ethernet
```

The Ethernet split test reached the main higher-layer milestones:

```text
CU_handle_F1_SETUP_REQUEST
Accepting DU 3586, sending F1 Setup Response
SIB8 warning request sent over F1AP
Jetson DU received Write Replace Warning Request from CU
cell PLMN 001.01 Cell ID 12345678 is in service
```

Packet capture on `serber-firecell` also confirmed SCTP heartbeats between the Jetson DU and the CU:

```text
10.76.170.8 -> 10.76.170.38: sctp HEARTBEAT REQUEST
10.76.170.38 -> 10.76.170.8: sctp HEARTBEAT ACK
```

This means the custom kernel, OAI build, CU/DU configuration, F1-C path, and network-side SIB8/PWS path are functional.

The first user-plane check failed because the CU sent F1-U to Jetson on UDP `2153` while the Jetson DU runtime was listening on UDP `2152`. After correcting the runtime and TUI generation to use `2153`, external-DN traffic reached the live UE data IP:

```text
external_dn_ping:
  target: 10.0.0.2
  result: 5 transmitted, 5 received, 0% packet loss
  rtt_average: about 26.5 ms

f1_u_capture:
  direction: bidirectional
  path: 10.76.170.38:2153 <-> 10.76.170.8:2153
```

---

## USB link-speed issue and fix

The main hardware blocker was below OAI. The B210 initially enumerated on the Jetson as a USB 2.0 high-speed device instead of a USB 3.0 SuperSpeed device:

```text
initial_state:
  b210_path: Bus 001
  b210_speed: 480M
  result: sustained UHD receive overflows
```

For the 106 PRB configuration, the DU uses `-E` and streams at `46.08 MSps`. This requires a SuperSpeed USB path. At `480M`, the Jetson cannot sustain the required sample transfer rate and the DU log fills with UHD receive overflows:

```text
Actual RX sample rate: 46.080000MSps
ERROR_CODE_OVERFLOW
problem receiving samples
```

The Jetson itself does expose a SuperSpeed USB tree:

```yaml
jetson_usb3_tree:
  root_bus: Bus 002
  root_speed: 10000M
```

The fix was to use the Jetson USB-C port with a USB 3.0-capable hub. With that path, the B210 enumerates correctly:

```yaml
fixed_state:
  b210_path: Bus 002
  b210_speed: 5000M
  driver: usbfs
  uhd_device: USRP B210 serial 8002816
```

This removed the USB 2.0 transport ceiling.

---

## Runtime tuning applied

The usual CPU and USB tuning was applied first. After the B210 reached USB 3.0 speed, the remaining overflows were removed by changing the Jetson DU launch shape.

| Setting | State |
| --- | --- |
| Jetson power mode | `MAXN_SUPER` |
| `jetson_clocks` | enabled |
| CPU governors | `performance` |
| CPU idle states | disabled |
| Fan | maximum |
| USB autosuspend | disabled |
| `usbfs_memory_mb` | `1000` |
| SCTP kernel module | loaded |
| B210 USB speed | `5000M` |
| DU log level | `warning` |
| DU CPU affinity | CPUs `1-5` |
| USB IRQ affinity | CPU `0` |

The final TUI launch uses quieter DU logging and keeps the OAI softmodem off CPU 0, leaving CPU 0 for USB/kernel interrupt work. This produced the cleanest observed Jetson result:

```yaml
jetson_ethernet_result:
  f1_setup: pass
  sib8_pws_path: pass at CU/DU log level after DU-side patch rebuild
  f1_u_port: 2153
  external_dn_to_live_ue_ip: pass
  b210_speed: 5000M
  sample_rate: 46.08 MSps
  startup_overflow_count: 0
  sustained_overflow_sample: 0 overflows over 120 seconds
```

One important correction was needed for PWS. The CU was already building SIB8 and sending `F1AP_WRITE_REPLACE_WARNING`, but the Jetson DU binary initially had no handler for procedure code `20`. Applying the existing SIB8/PWS patch to the Jetson OAI checkout and rebuilding `nr-softmodem` fixed this. After restart, the DU log showed:

```text
received Write Replace Warning Request from CU
got sync (ru_thread)
got sync (L1_stats_thread)
ERROR_CODE_OVERFLOW count: 0
```

---

## Comparison with working B210 baselines

The same B210 serial `8002816` is known to work in other lab configurations when it is attached through a proper SuperSpeed path.

| Area | Working B210 split baselines | Jetson current state |
| --- | --- | --- |
| F1-C association | Working | Working |
| F1-U/user-plane | Working | External-DN ping to live UE IP passes |
| SIB8/PWS path | Working | Working at CU/DU log level after Jetson DU patch rebuild |
| B210 link speed | SuperSpeed USB expected | USB 3.0, 5000M |
| 106 PRB stability | Stable on validated hosts | Stable in current 120 second Jetson sample |
| Phone attach and throughput | Validated on previous baselines | 5G bars observed; phone-side browser/speed test has NO internet |
| Phone-visible PWS alert | Validated on previous baselines | Confirmed working (PWS alert received on handset) |

The Jetson work therefore reached the same machine-side access-DU milestones as the previous B210 split baselines, and now also has lab-side user-plane proof and phone-visible PWS confirmation. The remaining missing validation is phone-visible internet data routing to the Nothing Phone.

---

## Interpretation

The Jetson Orin Nano is now a viable OAI DU software platform. It has the correct SCTP kernel support, native UHD support, a compiled OAI DU binary, TUI integration, F1AP association, bidirectional F1-U, and a stable 106 PRB B210 runtime window over USB 3.0.

The handset successfully attaches (displays 5G bars) and receives network SIB8 PWS alerts. However, it cannot browse the internet or run a speed test, indicating a user-plane data routing or translation failure downstream from the external DN or within the core/UPF configuration for this specific subscriber/APN path.

---

## Next Steps

1. Troubleshoot the commercial phone internet path: verify the APN/DNN configuration matches `oai`.
2. Inspect the UPF session data and IP configuration (e.g. comparing UE IP and NAT rules on the core host).
3. Record a synchronized evidence bundle (sanitized of secrets) tracing where user-plane packets are dropped.
4. Only after Ethernet is fully verified with phone internet and PWS, return to Jetson Quectel/WireGuard backhaul validation.
