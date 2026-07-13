# oai-pc X310 Transport Discovery

## Objective

Move the X310 access-cell transport test away from the MiniPC 1 GbE path and
check whether `oai-pc` can provide a real high-speed NIC path while keeping SSH
management on Wi-Fi.

## Date

2026-07-06, observed from the local Codex shell around `14:19` Asia/Riyadh
after the operator reconnected `oai-pc` Ethernet.

## Starting Decision

Use `oai-pc` as the next candidate host, not `serber-firecell`.

Reason:

- `serber-firecell` inventory showed only an Intel I225-V Ethernet controller
  with `10/100/1000/2500baseT` support and a current `1000Mb/s` link.
- `serber-firecell` Wi-Fi interfaces were present but not associated.
- `serber-firecell` is the active 5GC/CU and rollback/core host.
- `oai-pc` is the historical higher-power DU candidate and currently resolves
  to `10.76.170.24`.

No password, private key, raw log, packet capture, or credential material was
recorded.

## Read-First Context

The following repository guardrails were checked before live probing:

- `AGENTS.md`
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `experiments/20260706_x310_cat8_transport_and_f1_setup.md`
- `experiments/20260625_x310_51prb_access_cell_verification.md`

Relevant baseline rule: Ethernet CU/DU with B210/SIB8 remains the rollback
baseline. X310 work must not be reported as PASS without synchronized transport,
F1, UE, PWS, and throughput evidence.

## Local Reachability Result

DNS resolution from the local shell:

```text
oai-pc.kaust.edu.sa -> 10.76.170.24
oai-pc -> oai-pc.kaust.edu.sa -> 10.76.170.24
```

After Ethernet was reconnected, the host was reachable:

```text
ping oai-pc.kaust.edu.sa: 2 packets transmitted, 2 packets received
nc oai-pc.kaust.edu.sa 22: succeeded
ssh-keyscan -T 5 -H oai-pc.kaust.edu.sa: 8 known_hosts lines collected
```

Authenticated SSH as `oai` succeeded and showed that the active management path
is still wired Ethernet:

```text
hostname: oai-pc
user: oai
enp5s0 UP 10.76.170.24/25
wlp0s20f3 DOWN
default via 10.76.170.126 dev enp5s0
```

The SSH login banner reported the client source as `10.85.160.16`, but the
remote host itself did not have Wi-Fi associated or routed. Therefore this is
not proof that `oai-pc` SSH would survive unplugging Ethernet.

## Wi-Fi Management Gate

Blocked.

`oai-pc` has an Intel Wi-Fi interface, but it was disconnected:

```text
0000:00:14.3 Network controller: Intel Corporation Alder Lake-S PCH CNVi WiFi
wlp0s20f3 driver: iwlwifi
nmcli radio: WIFI-HW enabled, WIFI enabled
wlp0s20f3:wifi:disconnected
```

Visible SSIDs included enterprise and local networks, but no connection was
made during this run:

```text
eduroam: WPA2 802.1X
iCampus: WPA2 802.1X
NETGEAR50: WPA2
```

Required before unplugging Ethernet:

- associate `wlp0s20f3` to a management network;
- obtain a Wi-Fi management IP;
- prove `ssh oai@<oai-pc-wifi-ip>` from the operator machine;
- keep a second persistent SSH session over Wi-Fi while Ethernet is moved.

## Ethernet NIC Inventory

`oai-pc` does not currently present a 10 GbE NIC. It has one 1 GbE Intel I219
interface and two Intel I225 2.5 GbE interfaces:

```text
0000:00:1f.6 Ethernet controller: Intel Corporation Ethernet Connection (17) I219-LM
0000:03:00.0 Ethernet controller: Intel Corporation Ethernet Controller I225-V
0000:05:00.0 Ethernet controller: Intel Corporation Ethernet Controller I225-LM
```

Interface details:

```text
enp0s31f6
driver: e1000e
bus-info: 0000:00:1f.6
Supported link modes: 10/100/1000baseT
Speed: Unknown, Link detected: no

enp3s0
driver: igc
bus-info: 0000:03:00.0
Supported link modes: 10/100/1000/2500baseT
Speed: Unknown, Link detected: no
MTU max: 9216

enp5s0
driver: igc
bus-info: 0000:05:00.0
Supported link modes: 10/100/1000/2500baseT
Speed: 1000Mb/s
Link detected: yes
MTU max: 9216
Active management IP: 10.76.170.24/25
```

Conclusion: `oai-pc` is not the requested high-speed X310 host in its current
hardware state. The best exposed NIC class is 2.5 GbE, and the active link is
only 1 GbE.

## Stage Gate Outcome

Blocked after Stage 1/2 discovery.

The required pre-recabling gates were not met:

- Wi-Fi management was not associated and had no IP;
- SSH was proven only over the Ethernet management path;
- no 10 GbE-capable Ethernet NIC was discovered;
- the active wired link was `1000Mb/s`;
- no Ethernet cable should be unplugged or repurposed based on this run.

This is a negative finding for using the current `oai-pc` as the 106-PRB X310
transport solution. A 2.5 GbE path may be useful for other experiments, but it
does not satisfy the 10 GbE-or-better gate for a real 106-PRB retry.

## Not Attempted

The following stages were intentionally not attempted because the management
and NIC gates failed:

- physical recabling from `oai-pc` Ethernet to X310;
- temporary `192.168.10.1/24` assignment on `oai-pc`;
- UHD `uhd_find_devices`, `uhd_usrp_probe`, or `benchmark_rate`;
- OAI CU/DU launch with `serber-firecell` as 5GC/CU and `oai-pc` as DU;
- phone registration, PWS/SIB8, or throughput validation.

## Required Next Action

Do not move the X310 to the current `oai-pc` Ethernet ports for a 106-PRB
transport claim. Choose one of these paths first:

- install or identify a real 10 GbE NIC/transceiver path on `oai-pc`;
- use another host with proven 10 GbE and independent management;
- bring up `oai-pc` Wi-Fi management only if the goal is to free one 2.5 GbE
  port for a lower-rate experiment.

If `oai-pc` later gains a 10 GbE path, rerun the safe gates:

```bash
ssh oai@<oai-pc-wifi-ip> 'hostname; date; ip -br addr; ip route'
ssh oai@<oai-pc-wifi-ip> 'for i in $(ls /sys/class/net); do ethtool "$i" 2>/dev/null | sed -n "1,80p"; done'
```

Only after `ssh oai@<oai-pc-wifi-ip>` works in a second persistent terminal
should the Ethernet cable be moved to the X310 path.

## Rollback And Safety

No live lab state was changed in this run. No host was readdressed, no cable was
moved, no Wi-Fi profile was modified, no runtime config was generated, and no
OAI process was started.

The B210 Ethernet CU/DU rollback baseline remains the demo fallback for phone
attach, internet, and PWS/SIB8.

## Follow-up: 106 PRB Attempt On oai-pc Spare NIC

After the operator connected the X310 path to `oai-pc` `enp3s0`, the test was
continued as a runtime-only experiment.

Management stayed on `enp5s0`:

```text
enp5s0 UP 10.76.170.24/25
```

The X310-facing port came up on `enp3s0`, but only at 1 GbE:

```text
enp3s0 UP 192.168.10.1/24
Speed: 1000Mb/s
Duplex: Full
Link detected: yes
```

Forcing `2500baseT` did not work; carrier dropped and the X310 stopped
responding until the link was restored to 1 GbE:

```text
Advertised link modes: 2500baseT/Full
Speed: Unknown
Link detected: no
ping 192.168.10.3: 100% packet loss
```

The restored 1 GbE path reached the X310:

```text
192.168.10.3 dev enp3s0 src 192.168.10.1
ping 192.168.10.3: 0% packet loss
UHD Device: serial 32B50AA, addr 192.168.10.3, fpga HG, product X310
```

Jumbo MTU was not usable on this path. Setting MTU `9000` or `8000` caused the
link to drop; the working path was MTU `1500`, so UHD reported:

```text
Maximum frame size: 1472 bytes
```

### F1 Attempt

A temporary firecell CU was started from the existing CU tree:

```text
CU OAI tree: /home/serber/cu-du-minipc-backhaul/source/openairinterface5g
CU OAI commit: 9e67011af10f73264356366a59df7545349d9dab
CU F1-C bind: 10.76.170.38:38472
CU F1-U bind: 10.76.170.38:2153
NGSetupResponse from AMF: observed
```

The `oai-pc` DU was started with a temporary runtime config:

```text
DU OAI tree: /home/oai/sib8-spoofing
DU OAI commit: 42128d314e7d3ca90b9bbaf91b3060f8cbebdf7b
DU binary banner: real-time 7d5fcbefb7
DU F1 local: 10.76.170.24
DU F1 remote CU: 10.76.170.38
X310 args: type=x300,addr=192.168.10.3,recv_frame_size=1472,send_frame_size=1472,otw=sc8
```

This did not reach radio activation because the lab hosts could not reach each
other directly on the management subnet:

```text
oai-pc -> firecell ping: 100% packet loss
firecell -> oai-pc ping: 100% packet loss
DU SCTP state: COOKIE_WAIT to 10.76.170.38:38472
```

Adding temporary host routes via the gateway did not fix the path. The F1
attempt was stopped before any phone or PWS validation.

### Local Radio Transport Attempts

To isolate radio transport from the blocked firecell F1 path, local `--phy-test`
runs were attempted on `oai-pc`.

The `sib8-spoofing` OAI build crashed before UHD initialization in local
monolithic/phy-test mode, immediately after local F1/SIB8 handling. To avoid
that pre-radio crash, the `cross-cell-verification` OAI tree was used for the
transport-only tests:

```text
Tree: /home/oai/cross-cell-verification
Commit: a39af6886a25ed26d88d3bca8cc9c3c0e043121f
Binary banner: develop a82077f4a0
Config basis: gnb0.prs.band78.fr1.106PRB.usrpx310.conf
Runtime-only SDR args: type=x300,addr=192.168.10.3,recv_frame_size=1472,send_frame_size=1472,otw=sc8
```

106 PRB with `-E` reached the X310 and started RF at 46.08 MSps, but failed
immediately on receive overflow:

```text
sample_rate 46080000 Hz
Found USRP x300
Maximum frame size: 1472 bytes
Actual RX sample rate: 46.080000MSps
Actual TX sample rate: 46.080000MSps
Mboard 0: X310
RU 0 rf device ready
ERROR_CODE_OVERFLOW
problem receiving samples
RfnocError: OpTimeout: Control operation timed out waiting for ACK
```

A tuned rerun with larger UHD frame queues and socket buffers reproduced the
same failure:

```text
num_recv_frames=4096
num_send_frames=4096
recv_buff_size=33554432
send_buff_size=33554432
Actual RX sample rate: 46.080000MSps
Actual TX sample rate: 46.080000MSps
ERROR_CODE_OVERFLOW
RfnocError: OpTimeout
```

Native 106 PRB without `-E` reached 61.44 MSps and then produced sustained
receive overflows until the bounded run timed out:

```text
sample_rate 61440000 Hz
Actual RX sample rate: 61.440000MSps
Actual TX sample rate: 61.440000MSps
RU 0 rf device ready
ERROR_CODE_OVERFLOW
problem receiving samples
RU 0 RF device stopped
```

### Follow-up Conclusion

The `oai-pc` spare-port attempt does not solve the 106 PRB X310 transport
blocker. Although `oai-pc` has Intel I225 2.5 GbE hardware, the X310 path
negotiated only `1000Mb/s`, jumbo MTU was not usable, and both 106 PRB modes
failed at the radio transport boundary:

- `-E` / 46.08 MSps: `RU 0 rf device ready`, then immediate
  `ERROR_CODE_OVERFLOW` and RFNoC `OpTimeout`.
- native / 61.44 MSps: `RU 0 rf device ready`, then sustained
  `ERROR_CODE_OVERFLOW`.

No PASS is claimed. The test did not reach an end-to-end CU/DU access cell,
phone attach, PWS observation, or throughput validation.

### Follow-up Cleanup

Temporary `nr-softmodem` processes were stopped on both `oai-pc` and
`serber-firecell`. Temporary `/32` route overrides were removed. The X310-facing
`enp3s0` link was restored to the working 1 GbE state after the failed 2.5 GbE
force attempt.
