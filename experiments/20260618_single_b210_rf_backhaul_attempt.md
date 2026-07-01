# Single-B210 RF Backhaul Attempt

Date: 2026-06-18

## Requested Action

Apply the temporary single-B210 RF backhaul experiment plan on `serber-minipc`:

- suppress Quectel/WireGuard for the experiment;
- probe USRP B210 serial `8002816`;
- keep Ethernet CU/DU with SIB8 as rollback;
- do not claim success without sanitized evidence.

## Result

Blocked before hardware or OAI validation.

The experimental TUI mode was run:

```bash
./scripts/oai-lab-tui --experimental-b210
```

It failed closed during Step 1, minipc discovery:

```text
serber-minipc SSH target is required for the experimental single-B210 mode
No PASS claimed.
```

Because discovery failed before Step 2, the run did not suppress Quectel,
stop remote OAI processes, write remote runtime files, or modify any live
remote configuration.

## Reachability Evidence

Direct SSH from the operator machine:

```text
ssh: connect to host 10.76.170.100 port 22: Operation timed out
```

Reachability from `serber-firecell`:

```text
PING 10.76.170.100: 100% packet loss
ip route get 10.76.170.100: dev enp6s0 src 10.76.170.38
ip neigh show 10.76.170.100: FAILED
```

The firecell management interface was up:

```text
enp6s0 UP LOWER_UP
10.76.170.38/25 on enp6s0
```

## Interpretation

`serber-minipc` was not reachable on the documented management address
`10.76.170.100` from either the operator machine or `serber-firecell`.
The failed neighbor/ARP state means the host was not visible on the expected
local management segment at the time of the attempt.

## Next Physical Checks

1. Confirm `serber-minipc` is powered on and booted.
2. Confirm its management Ethernet cable is connected to the expected lab
   network.
3. On the minipc console, verify its active IP address and SSH service:

```bash
ip -4 -br addr
systemctl status ssh
```

4. If the minipc IP changed, update the TUI lab configuration before rerunning:

```bash
./scripts/oai-lab-tui --experimental-b210
```

Only after minipc SSH works should the plan proceed to B210/UHD probing and
the no-Quectel packet gates.

## Follow-up Run: 2026-06-19

`serber-minipc` became reachable at the current management address
`10.76.170.83` on `enp4s0`.

The experimental mode was rerun:

```bash
./scripts/oai-lab-tui --experimental-b210
```

Evidence directory:

```text
experiments/20260619_131627_experimental_single_b210_rf_backhaul/
```

Completed gates:

```json
{
  "discovery": true,
  "quectelSuppressed": true,
  "b210": true,
  "runtimeMarker": true,
  "packetNoQuectel": true,
  "architectureProven": false
}
```

Key observations:

- `serber-minipc` was discovered through the current minipc path with
  `enp4s0` source IP `10.76.170.83`.
- Quectel control devices remained physically present, but no Quectel or
  WireGuard F1 path was active after suppression.
- Packet checks showed no F1 on `wg-quectel-f1`, `wwan0`, minipc management,
  or firecell management during the validation windows.
- UHD detected B210 serial `8002816`, operating over USB 3.
- The B210 exposed both TX frontends and both RX frontends.
- The minipc access DU config still uses `nb_tx = 1`, `nb_rx = 1`, and
  `num_cc = 1`; it is not yet a dual-role RF backhaul/access configuration.
- The minipc OAI tree was not at the pinned rollback commit. The observed
  short commit was `9e67011af1`.

Result:

```text
No PASS claimed.
```

The experiment successfully suppressed Quectel and proved the B210 hardware is
visible with two TX/RX chains, but the requested single-B210 backhaul plus
phone-access topology remains blocked until an OAI-supported dual-role
configuration or feature-separated patch is created and validated.

## Deeper Constraint Tests: 2026-06-19

The repeatable helper is:

```bash
./scripts/experimental-b210-rf-probe.sh
```

### UHD Subdevice Ownership

One process can open the B210 once and configure separate subdevices:

```text
specs A:A A:B
u1 channels 1 1
u2 channels 1 1
RESULT=two_handles_ok
```

But two separate processes cannot independently own the same B210:

```text
holder=A:A channels 1 1
opener=A:B failed:
LookupError: No devices found for serial=8002816
```

Interpretation: a stock `nr-uesoftmodem` process and a stock `nr-softmodem`
DU/gNB process cannot safely split the B210 by subdevice. A single RF owner is
required.

### B210 Channel Tuning

Both B210 channels were opened in one process:

```text
channels 2 2
```

When RX channel 0 was tuned to 3.60 GHz and RX channel 1 to 3.70 GHz, both
reported approximately 3.70 GHz. Retuning channel 0 to 3.60 GHz moved channel
1 back to approximately 3.60 GHz. TX behaved the same way.

Interpretation: the two B210 chains share tuning. They can support two-chain
MIMO/same-carrier work, but not independent access and backhaul carriers.

## Updated Conclusion

The one-B210 goal is not achievable as a stock OAI configuration change.

The viable one-board research path is a single RF owner:

- a combined OAI process that hosts both the UE/backhaul and DU/access roles;
  or
- an RF broker that opens the B210 once and exposes separate local RF endpoints
  to patched OAI UE and DU/gNB roles.

The lower-risk engineering path is separate RF hardware for backhaul and
access, but that does not satisfy the one-B210 drone payload goal.

## Broker Scaffold: 2026-06-19

Added a dry-run RF-simulator broker prototype:

```bash
./scripts/experimental-b210-rfsim-broker-prototype.py
```

The scaffold listens for two OAI rfsimulator clients:

- access endpoint, default port `5043`;
- backhaul endpoint, default port `5044`.

It parses OAI `samplesBlockHeader_t` framing and counts IQ blocks. A local
loopback smoke test with synthetic frames passed:

```text
access: block=1 size=2 nbAnt=1 ts=1000 beam_map=0x1
backhaul: block=1 size=2 nbAnt=1 ts=2000 beam_map=0x1
```

This does not yet drive the B210. It is the first concrete scaffold for the
single-RF-owner solution path: two OAI roles would talk rfsim to the broker,
and only the broker would open UHD/B210.

## Broker Single-Owner Smoke Test: 2026-06-19

The broker was extended to:

- send the OAI-style initial one-sample timing block on client connect;
- optionally return zero-filled IQ blocks at the received timestamp;
- open B210 serial `8002816` once as the single RF owner.

Local synthetic-client smoke test:

```text
initial 6043 (1, 1, 0, 0, 0, 1)
reply 6043 (2, 1, 1000, 0, 0, 1)
initial 6044 (1, 1, 0, 0, 0, 1)
reply 6044 (2, 1, 2000, 0, 0, 1)
```

Minipc smoke test while owning the B210:

```text
uhd_owner tx_channels=2 rx_channels=2 rx_freq0=3600000000 rx_freq1=3600000000
initial 5043 (1, 1, 0, 0, 0, 1)
reply 5043 (2, 1, 3000, 0, 0, 1)
initial 5044 (1, 1, 0, 0, 0, 1)
reply 5044 (2, 1, 4000, 0, 0, 1)
```

This proves the next architecture step is executable on the target host: one
process can own the B210 and serve two rfsim-compatible endpoints. It still
does not prove RF backhaul or phone access, because the broker does not yet
stream UHD samples or connect to live OAI processes.

## Real OAI RFSIM Handshake: 2026-06-19

The broker was extended with a periodic zero-IQ clock mode:

```bash
./scripts/experimental-b210-rfsim-broker-prototype.py \
  --send-initial \
  --zero-fill \
  --clock-tick-size 30720 \
  --clock-tick-period 0.001
```

A temporary loopback-only CU/DU test was run on `serber-minipc`. The test used
copies under `/tmp` so the checked-in configs and rollback baseline were not
modified:

- CU config: NG/NG-U temporary loopback address `127.0.0.5`, F1-C/F1-U
  loopback address `127.0.0.4`;
- DU config: rfsimulator client target `127.0.0.1:5043`;
- broker access endpoint: `5043`;
- no Quectel or WireGuard F1 path was used.

With the broker owning B210 serial `8002816`, the broker reported:

```text
uhd_owner tx_channels=2 rx_channels=2 rx_freq0=3619200000 rx_freq1=3619200000
access: connected from 127.0.0.1:36100
access: block=1 size=30720 nbAnt=1 ts=184320 beam_map=0x1 option=0x0/0
access: block=100 size=30720 nbAnt=1 ts=3225600 beam_map=0x1 option=0x0/0
access: block=1000 size=30720 nbAnt=1 ts=30873600 beam_map=0x1 option=0x0/0
access: block=10000 size=30720 nbAnt=1 ts=307353600 beam_map=0x1 option=0x0/0
access: blocks=65057 samples=1998551040 last_timestamp=1998704640
```

The local CU/DU control plane also completed F1 setup and delivered the SIB8
warning path to the DU:

```text
Received F1 Setup Request from gNB_DU 3584
Accepting DU 3584, sending F1 Setup Response
received F1 Setup Response from CU gNB-Eurecom-CU
DU_handle_WriteReplaceWarning: sib_type=8, seg_len=92
Connection to 127.0.0.1:5043 established
RFsim: Number of antennas changed from 0 to 1
```

Interpretation:

- A real OAI DU/gNB process can connect to the experimental broker over
  rfsimulator and exchange OAI IQ blocks.
- The same broker process can simultaneously own the B210 as the only UHD
  owner.
- This validates the single-RF-owner architecture path for the access side.
- The run remains a protocol/architecture proof only. It does not yet stream
  real UHD samples, validate the backhaul UE endpoint, or attach the Nothing
  Phone over RF.

Cleanup check:

```text
No leftover experimental broker, nr-softmodem, or nr-uesoftmodem process was
observed after the timed run.
```

Next required step: replace zero-fill/clock-tick behavior with UHD streaming
inside the broker, then repeat the same gate with both access and backhaul OAI
rfsim endpoints connected.

## Live Two-Channel UHD Bridge: 2026-06-19

The broker now has an opt-in UHD streaming backend:

```bash
--uhd-stream
--uhd-rx-only
--tx-gain 0
--rx-gain 30
```

It creates one synchronized two-channel RX streamer and one two-channel TX
streamer. Access maps to B210 channel 0 and backhaul maps to B210 channel 1.
The existing zero-fill mode remains available as a fallback.

### Bandwidth Gate

Three bandwidths were tested:

```text
106 PRB: OAI requests 61.44 Msps; UHD rejects two-channel streaming because
         the B210 maximum tick rate is 30.72 MHz.

24 PRB:  OAI requests 15.36 Msps; radio initialization succeeds, but the OAI
         scheduler cannot allocate the 94-byte SIB8 transport block.

51 PRB:  OAI uses 30.72 Msps; F1 setup and SIB8 delivery succeed, and the
         profile fits the two-channel B210 rate limit.
```

The validated experimental carrier for the broker is:

```text
N_RB=51
sample_rate=30720000
center_frequency=3609300000
```

### Access Endpoint With Live B210 Samples

A real OAI DU/gNB used the access endpoint while the broker returned live B210
channel-0 samples:

```text
uhd_owner tx_channels=2 rx_channels=2
uhd_stream mode=rx_only channels=0,1
access: blocks=20788 samples=319303680
uhd_rx_blocks=20564 uhd_rx_timeouts=224
```

The local CU accepted the DU and delivered the SIB8 warning during the run.
No SIB8 scheduler assertion was observed at 51 PRB.

A short minimum-gain TX/RX test also passed the sample-mapping gate:

```text
uhd_stream mode=rx_tx channels=0,1
access: blocks=2377
uhd_tx_blocks=2377 uhd_rx_blocks=1946
```

UHD printed TX underflow markers because the prototype writes isolated blocks
instead of maintaining a continuously paced TX buffer. This is not yet a
quality RF waveform claim.

### Backhaul Endpoint With A Real OAI UE

`nr-uesoftmodem` was launched from `/tmp` so its transient statistics files
did not modify the OAI tree. The broker recorded:

```text
Connection to 127.0.0.1:5044 established
backhaul: blocks=18920 samples=290611200
uhd_rx_blocks=18837 uhd_rx_timeouts=83
```

The UE repeatedly attempted synchronization. It did not synchronize because no
donor-cell waveform was present on the backhaul antenna during the test.
Subscriber values from the raw UE log were not copied into the repository.

### Concurrent OAI Roles

The real access DU and backhaul UE were then run concurrently against the same
broker and the same B210:

```text
access: connected on port 5043
backhaul: connected on port 5044
access: blocks=11963 uhd_rx_blocks=11502
backhaul: blocks=2600 uhd_rx_blocks=2538
```

This proves the requested process topology at the IQ bridge level:

- one process owns B210 serial `8002816`;
- OAI access DU/gNB uses logical channel 0;
- OAI backhaul UE uses logical channel 1;
- both roles receive live B210 samples concurrently;
- F1 setup and SIB8 remain active on the access DU.

It does not yet prove donor synchronization, Nothing Phone attachment, or
traffic forwarding between the two roles.

### Remaining Engineering Work

1. Replace bursty two-channel TX writes with a continuous timed ring buffer.
2. Pair access and backhaul TX blocks without zeroing the other active channel.
3. Drive rfsim timestamps from UHD hardware time instead of synthetic seed
   ticks.
4. Provide a live donor waveform on the backhaul antenna and prove UE sync.
5. Attach the Nothing Phone on the access antenna and collect sanitized traffic
   evidence.
6. Stop the experiment and validate the documented Ethernet CU/DU rollback.

## Three-Quarter Sampling And Paired Workers: 2026-06-19

The 51-PRB full-duplex test at 30.72 Msps showed that the Python broker and
USB path were too close to their processing limit. Thousands of UHD underflow
markers were observed even after grouping TX blocks.

OAI three-quarter sampling was then enabled with `-E` on both the DU and UE.
The 51-PRB block size changed from `15360` to `11520` samples per half-slot,
confirming a rate reduction from 30.72 Msps to 23.04 Msps.

This retained the required behavior:

```text
received F1 Setup Response from CU
received Write Replace Warning Request from CU
no SIB8 allocation assertion
```

The broker was also extended with:

- a dedicated two-channel TX worker;
- bounded per-channel TX queues;
- eight-block paired UHD TX batches;
- a dedicated continuous two-channel RX worker;
- active-endpoint filtering for RX queues;
- a selector fairness limit for the two rfsim sockets.

### Stable Access Full-Duplex Run

At 23.04 Msps with `-E`:

```text
uhd_stream mode=rx_tx channels=0,1 tx_batch=8 rx_batch=1
access: blocks=9969 samples=114842880
uhd_tx_blocks=9969
uhd_rx_blocks=9957
uhd_rx_timeouts=12
uhd_rx_summary captured_blocks=23981 dropped_blocks=0
uhd_tx_summary sent_blocks=3033 dropped_blocks=0
uhd_underflow_markers=19
uhd_overflow_markers=46
```

This is the current best access-side operating point.

### Dual OAI Full-Duplex Run

The DU and UE were then run concurrently with `-E`, using one B210 owner:

```text
access: blocks=11653 samples=134242560
access: uhd_tx_blocks=11653 uhd_rx_blocks=11452

backhaul: blocks=2240 samples=25804800
backhaul: uhd_tx_blocks=2240 uhd_rx_blocks=2240

uhd_tx_summary sent_blocks=4531 dropped_blocks=0
uhd_underflow_markers=101
uhd_overflow_markers=350
```

F1 setup and SIB8 remained active. The UE connected to port `5044` and began
sync detection, but no donor waveform was available.

The two OAI roles do not yet consume broker samples at the same rate. The
slower backhaul UE causes old channel-1 captures to be dropped from the bounded
queue, so contiguous donor samples are not yet guaranteed.

### Rejected Narrower-Bandwidth Branches

- 38 PRB was rejected by this OAI build with:

```text
N_RB 38 not yet supported for numerology 1
```

- 24 PRB uses only 15.36 Msps, but one standards-sized warning page still
  encodes to a 94-byte SI payload. The scheduler cannot place it in the
  available 24-PRB SI slot.
- Experimental TDA changes did not solve the 24-PRB collision. The external
  OAI scheduler source was restored byte-for-byte from its pre-test backup and
  `nr-softmodem` was rebuilt after restoration.

## Current Best Candidate

```text
carrier bandwidth: 51 PRB
OAI sampling mode: -E
broker sample rate: 23.04 Msps
backhaul endpoint: 127.0.0.1:5044 -> B210 chain A (TX/RX A + RX2 A)
access endpoint: 127.0.0.1:5043 -> B210 chain B (TX/RX B + RX2 B)
broker TX batch: 8 OAI blocks
```

This is a working dual-OAI, single-owner, two-channel IQ bridge. The remaining
completion gates are donor synchronization, backhaul registration, Nothing
Phone attachment, and user traffic forwarding. Contiguous dual-endpoint timing
and Ethernet rollback have since been validated.

## Native Broker And Contiguous Dual Timing: 2026-06-20

A compiled C++/UHD broker was added under the feature patch directory. It uses
native `sc16` buffers and independent rfsimulator socket readers and writers.
The latter is required because OAI UE performs RX before TX during initial
synchronization; a request/reply bridge stalls at timestamp zero.

Real OAI UE-only evidence against B210 channel 1:

```text
backhaul input_blocks=27040 output_blocks=27096
input_timestamp_gaps=0 rx_dropped_newest=0 tx_dropped_oldest=0
uhd rx_metadata_errors=7 tx_short_sends=0
```

Real access CU/DU evidence against B210 channel 0:

```text
access input_blocks=24919 output_blocks=24939
input_timestamp_gaps=0 rx_dropped_newest=0 tx_dropped_oldest=0
F1 Setup Response received
Write Replace Warning Request received
```

Those measurements used the original logical test mapping. After validation,
the final native mapping was changed to match the requested connector names:
backhaul uses chain A and access uses chain B. The final source compiled against
the MiniPC UHD 4.8 headers while the restored Ethernet DU remained active.

Concurrent real access DU and backhaul UE evidence through one B210 owner:

```text
access input_blocks=30835 output_blocks=30843 input_timestamp_gaps=0
backhaul input_blocks=34960 output_blocks=35020 input_timestamp_gaps=0
both endpoints rx_dropped_newest=0 tx_dropped_oldest=0
uhd rx_blocks=45479 rx_metadata_errors=15 tx_short_sends=0
```

The CU accepted F1 setup, marked the access cell in service, and delivered the
SIB8 warning while the backhaul UE repeatedly ran synchronization detection.
This resolves the earlier Python broker starvation and contiguous-timeline
blocker at the IQ bridge layer.

## Live Donor RF Reachability Gate: 2026-06-20

The firecell B210 donor was started on its validated 51-PRB profile:

```text
carrier=3619200000
sample_rate=23040000
PCI=1 TAC=2
cell in service
```

The MiniPC backhaul UE remained unable to synchronize. Short raw IQ snapshots
were retained only in `/tmp`; sanitized power summaries across all MiniPC B210
receive connectors were approximately `-52` to `-57 dBFS`. Reducing donor TX
attenuation from 24 to 10, a 14 dB increase, did not change those readings.
The live donor waveform therefore did not reach the MiniPC antennas in the
current physical arrangement. The likely gate is the cage boundary: a
backhaul antenna needs to be outside the cage or connected through a safe RF
feedthrough.

The donor was stopped and its temporary runtime attenuation restored to 24.

## Ethernet Rollback Revalidation: 2026-06-20

After stopping the experiment, the canonical split core, CU, and MiniPC DU
were restarted. Sanitized evidence showed:

```text
CU accepted DU 3585 and marked access cell 12345678 in service
DU received F1 Setup Response and Write Replace Warning Request
DU found B210 serial 8002816
SCTP ESTAB 10.76.170.83%enp4s0 -> 10.76.170.38:38472
wwan0 DOWN; usb0/rmnet_data0/wg-quectel-f1 absent
```

The Ethernet CU/DU SIB8 rollback is therefore preserved and is the active lab
state after this experiment.

## Donor Decode And Native-UHD Control: 2026-06-20

The earlier RF-reachability conclusion was superseded after using the donor's
actual 51-PRB SSB parameter (`--ssb 186`) and MiniPC chain-A `RX2`. The native
broker repeatedly decoded the donor PBCH and PCI 1. A 7 kHz B210 center-frequency
correction reduced the measured residual carrier offset to a few hundred hertz.

The strongest control bypassed the broker and ran stock `nr-uesoftmodem`
directly on MiniPC B210 serial `8002816`. With the calibrated gain request, it
reached:

```text
Initial sync successful, PCI: 1
SIB1 decoded
PRACH scheduled and transmitted (10 attempts)
```

The firecell donor did not report those PRACH attempts, so registration and a
PDU session were not established. This proves the downlink donor waveform and
native OAI receive path through SIB1, but not an RF backhaul attachment.

## Native Broker PHY Boundary: 2026-06-20

The broker was hardened with delayed RF startup, hardware-time gap accounting,
optional RX-only/backhaul-only modes, on-demand TX startup, 20 MHz RF filtering,
bounded digital gain, B210-compatible RX right shifting, and aligned UHD/rfsim
timestamps. Real-time CPU isolation and RX shifts from zero through four bits
were tested. The best broker path remained:

```text
Initial sync successful, PCI: 1
UE synchronized
Got NACK on NR-BCCH-DL-SCH-Message (SIB1)
```

The NACK originates from the genuine DL-SCH CRC-failure path. Stock native UHD
decoded the same SIB1, while the rfsim bridge did not, so further work should
move the shared-B210 transport into an OAI device integration that preserves
native UHD read/timestamp semantics. The socket broker remains an experimental
PBCH/dual-endpoint instrument and is not a working backhaul.

After these controls, the Ethernet CU/DU rollback was revalidated again: F1
Setup, Write Replace Warning/SIB8, B210 sync, and SCTP over
`enp4s0`/`enp6s0` were present; `wwan0` was down and `wg-quectel-f1` absent.

## Device-Layer Client Scaffold: 2026-06-20

The first feature-separated device-layer component was added under
`patches/experimental-b210-rf-backhaul/`. It implements an OAI
`openair0_device` client over a versioned binary local protocol and forwards:

- exact `trx_read` sample counts and first-sample timestamps;
- TX timestamps and burst flags;
- retune, gain, and bandwidth changes;
- explicit UHD/queue counters.

Control, RX, and TX have independent connections so a blocking UE RX call
cannot prevent PRACH TX. The client compiled against pinned OAI commit
`102965a669b9444857c27843ec8ce62780bf9d37` and exported the required
`device_init` symbol:

```text
device_client_build=ok output=/tmp/liboai_b210_device.so
```

This is not a Stage-1 PASS. The matching single-UHD-owner server is not yet
implemented, so native SIB1 equivalence has not been tested through this path.
The Ethernet CU/DU rollback remained active during this compile-only step.

## Experiment retired and normal TUI restored: 2026-06-21

The single-B210 path did not reach the required RF backhaul registration and
was removed from the operator TUI. Its local broker, device-client, device-owner,
probe, and continuation-prompt files were removed. Temporary deployed binaries,
custom device libraries, sockets, configs, logs, and experimental processes were
also removed from `serber-minipc` and `serber-firecell`.

The TUI again exposes only the three normal MiniPC configurations:

1. Monolithic firecell core and gNB.
2. Ethernet CU/DU with the MiniPC access DU.
3. Caged Quectel F1 backhaul with the monolithic firecell donor.

Fresh validation showed that monolithic passed all eight startup gates and
Ethernet passed all twelve rollback gates. The Quectel workflow reached the
expected donor cell on PCI 1 and TAC 2 but failed closed at modem registration
because it remained in limited service and the donor observed no PRACH. The lab
was finally left on the validated Ethernet CU/DU baseline with F1 Setup, SIB8,
B210 service, and no active Quectel or WireGuard backhaul.
