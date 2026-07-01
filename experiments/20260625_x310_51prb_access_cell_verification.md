# X310 51 PRB Access Cell Verification

## Objective

Verify the Ethernet CU/DU access cell after migrating the DU radio from the
B210 to the USRP X310 at `51` PRBs, native `30.72 MSps`, with the SSB kept on
ARFCN `641280`.

## Hypothesis

The shifted Point A and 51-PRB BWP allow the X310 DU to broadcast the access
cell without the CORESET#0 assertion, maintain F1-C association, schedule
SIB8/PWS, and support Nothing Phone attach and user-plane internet.

## Date

2026-06-25, observed from the lab hosts around `11:47` Asia/Riyadh.

## Topology

- Core/CU: `serber-firecell` at `10.76.170.38`
- DU/radio: `serber-minipc`
- F1 transport: Ethernet
- Radio: USRP X310 at `192.168.10.3`
- UE target: Nothing Phone, APN/DNN `oai`

## Hosts And Hardware

- `serber-minipc` DU process was active with `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf`.
- `serber-firecell` AMF and CU processes were active.
- X310 NIC interface `enp4s0` was up with `192.168.10.1/24`.
- CPU governor on `serber-minipc` reported `performance`.

## Repository Commit

Local control repository commit at collection time:

```text
8a2c7e262f9f55f329fb895788386936044dc2bc
```

The local worktree had unrelated existing modifications and was not committed
as part of this verification.

## OAI Commit

Both live CU and DU OAI trees reported:

```text
9e67011af10f73264356366a59df7545349d9dab
```

The runtime CU log banner still reported abbreviated build hash `102965a669`,
matching the older Ethernet rollback baseline. Future reproductions should
explicitly record both the source-tree HEAD and the built binary banner before
changing the deployed tree.

## Configs/Patches Used

The DU runtime config contained the expected 51-PRB/X310 values:

```text
absoluteFrequencySSB = 641280;
dl_absoluteFrequencyPointA = 640656;
dl_carrierBandwidth = 51;
initialDLBWPlocationAndBandwidth = 13750;
ul_carrierBandwidth = 51;
initialULBWPlocationAndBandwidth = 13750;
sdr_addrs = "type=x300,addr=192.168.10.3,recv_frame_size=8000,send_frame_size=8000,otw=sc8";
clock_src = "internal";
```

The local TUI change under test starts the DU without `-E`, allowing native
`30.72 MSps` rather than 3/4 sampling.

## Commands Executed

Only read-only inspection commands were run during this collection:

```bash
./scripts/oai-lab-tui --status
ssh serber-minipc 'tail/grep /tmp/oai-du-ethernet.log'
ssh serber@10.76.170.38 'tail/grep /tmp/oai-cu-ethernet.log'
ssh serber-minipc 'grep /tmp/oai-tui-gnb-minipc-ethernet-runtime.conf'
ssh serber-minipc 'ip -br addr show enp4s0; ethtool -S enp4s0'
ssh serber-minipc 'git -C /home/serber/cu-du/source/openairinterface5g rev-parse HEAD'
ssh serber@10.76.170.38 'git -C /home/serber/cu-du-minipc-backhaul/source/openairinterface5g rev-parse HEAD'
```

## Evidence And Sanitized Log Extracts

TUI status reported the running configuration as Ethernet CU/DU split.

DU process evidence:

```text
./nr-softmodem -O /tmp/oai-tui-gnb-minipc-ethernet-runtime.conf --log_config.global_log_level info
```

X310 and native sample-rate evidence:

```text
[HW]     UHD version 4.8.0.HEAD-0-g308126a4 (4.8.0)
[HW]       Actual RX sample rate: 30.720000MSps...
[HW]       Actual TX sample rate: 30.720000MSps...
  Mboard 0: X310
[HW]     [RAU] has loaded USRP X300 device.
[PHY]    RU 0 rf device ready
```

NIC and host stability evidence:

```text
enp4s0 UP 192.168.10.1/24 192.168.40.1/24
tx_errors: 0
rx_errors: 0
rx_missed: 0
```

During the first inspected window, the DU had not yet printed UHD
overflow/drop/underflow/late-timeout runtime lines. A later tail showed the DU
hit receive overflows and stopped:

```text
[HW]     [recv] received 14984 samples out of 15360
ERROR_CODE_OVERFLOW (Out of sequence error)
[PHY]    rx_rf: Asked for 15360 samples, got 14984 from USRP
[PHY]    problem receiving samples
[HW]     [recv] received 3568 samples out of 15360
ERROR_CODE_OVERFLOW (Out of sequence error)
[PHY]    rx_rf: Asked for 15360 samples, got 3568 from USRP
[PHY]    problem receiving samples
```

At `12:13` Asia/Riyadh, `serber-minipc` no longer showed an `nr-softmodem`
process for the DU. The CU then logged SCTP shutdown and DU release:

```text
[SCTP]   Received SCTP SHUTDOWN EVENT
[F1AP]   Received SCTP state 1 for assoc_id 1569, removing endpoint
[NR_RRC] releasing DU ID 3585 (gNB-CU-MINIPC) on assoc_id 1569
```

F1-C and CU association evidence:

```text
[NGAP]   Received NGSetupResponse from AMF
[NR_RRC] Received F1 Setup Request from gNB_DU 3585 (gNB-CU-MINIPC) on assoc_id 1569
[NR_RRC] Accepting DU 3585 (gNB-CU-MINIPC), sending F1 Setup Response
```

DU-side F1 response and PWS scheduling evidence:

```text
[MAC]    received F1 Setup Response from CU gNB-CU-MINIPC
[F1AP]   DU_handle_WriteReplaceWarning: sib_type=8, seg_len=92, transaction_id=0, rep_period=1280, num_broadcast=1
[NR_MAC] Configured PWS/SIB8 SI segment 0 at payload index 0 length 94
[NR_MAC] Configured PWS/SIB8 SI: 1 segment(s), payload index 0..0, SIB1 length 104
```

RF access attempts were present, proving that at least one UE was attempting
RACH against the cell:

```text
raproc_count=232
ra_failed_count=172
cannot_find_free_cce_count=114
ue_success_markers=0
```

Representative failure signature:

```text
[NR_PHY] [RAPROC] 603.19 Initiating RA procedure with preamble 59, energy 54.9 dB
[NR_MAC] UE a01b: 604.10 cannot find free CCE for Msg2!
[NR_MAC] UE 011d RA failed at state WAIT_Msg3 (Reached msg3 max harq rounds)
```

## Final Runtime State

Not passed.

The DU initially reached X310 RF-ready state and completed F1 setup, but later
stopped after UHD receive overflows. The CU remained running and released the DU
after SCTP shutdown.

## UE Registration Outcome

Not passed.

The DU log showed repeated RACH attempts, but no inspected DU or CU log lines
showed `RRCSetup`, `InitialUEMessage`, NAS registration, `5GMM-REGISTERED`,
DRB setup, or PDU-session establishment. Machine-side evidence therefore does
not support a successful Nothing Phone attach claim for this run.

## SIB8/PWS Outcome

Partially verified.

The CU-to-DU warning path and DU MAC SIB8/PWS scheduling were verified in logs.
Phone-side emergency alert reception was not verified in this collection.

## Throughput Result

Not measured. No phone PDU session or user-plane traffic was proven during the
collection window.

## Comparison To Baseline

- Preserved: Ethernet CU/DU split startup, AMF NG setup, F1-C association, and
  SIB8/PWS scheduling path.
- Changed: access radio is X310 at `51` PRBs and native `30.72 MSps`.
- Not yet matched: the rollback baseline's phone registration, user-plane
  internet, and observed throughput evidence.

## Conclusion

The X310 51-PRB access cell reached the intended machine-side milestones:
native `30.72 MSps` UHD startup, F1-C association, and DU-side SIB8/PWS
scheduling. It did not survive long enough to complete phone validation. The
live RF evidence stopped at failed RA, with repeated Msg2 CCE pressure, Msg3
failures, and final UHD receive overflows that caused DU shutdown. Do not claim
full access-cell PASS until the DU remains stable, the Nothing Phone reaches
registration, receives PWS, and proves user-plane internet.

## Rollback Procedure

Use the documented Ethernet CU/DU rollback path through the TUI. If X310
testing must be abandoned, restore the previous B210 DU runtime config outside
Git and relaunch the Ethernet CU/DU split. Confirm F1 setup, phone registration,
PWS/SIB8 reception, and user-plane throughput before declaring the rollback
healthy.

## Next Action

With the Nothing Phone in hand:

1. Confirm APN/DNN is `oai`.
2. Relaunch the DU and watch for any `ERROR_CODE_OVERFLOW` or short-read lines.
3. Toggle Airplane Mode and watch DU/CU logs for progression beyond RACH.
4. If RA still fails, reduce contention or adjust CORESET/RA scheduling pressure
   before changing core/user-plane settings.
5. Once registration succeeds, run phone ping/speed test and capture sanitized
   PWS/throughput evidence in a new experiment window.

## Follow-up: 106 PRB Trial

After the first 51-PRB check, the DU was reconfigured to try `106` PRBs with
RIV `28875` while keeping `absoluteFrequencySSB = 641280` and
`dl_absoluteFrequencyPointA = 640656`.

Native 106-PRB startup was accepted by OAI and reached the same machine-side
milestones:

```text
N_RB 106
sample_rate 61440000 Hz
Actual RX sample rate: 61.440000MSps
Actual TX sample rate: 61.440000MSps
received F1 Setup Response from CU gNB-CU-MINIPC
Configured PWS/SIB8 SI segment 0
RU 0 rf device ready
```

It failed immediately after RF start on the minipc/X310 path:

```text
[recv] received 1612 samples out of 30720
ERROR_CODE_OVERFLOW (Overflow)
rx_rf: Asked for 30720 samples, got 1612 from USRP
problem receiving samples
```

The same 106-PRB config was then tried with `-E`, reducing the sample rate to
`46.08 MSps`, plus additional transport tuning:

```text
num_recv_frames=1024
num_send_frames=1024
recv_buff_size=33554432
send_buff_size=33554432
enp4s0 IRQ affinity pinned to CPU 3, then CPU 2
```

The `-E` run also reached F1/PWS/RF-ready state but still failed immediately:

```text
Actual RX sample rate: 46.080000MSps
Actual TX sample rate: 46.080000MSps
RU 0 rf device ready
ERROR_CODE_OVERFLOW (Overflow)
RfnocError: OpTimeout: Control operation timed out waiting for ACK
```

Host inspection found no alternate high-speed X310 path:

```text
enp4s0 Speed: 1000Mb/s
enp2s0 Speed: 1000Mb/s
X310 discovered only at 192.168.10.3 on enp4s0
```

Conclusion for 106 PRB: blocked on the current `serber-minipc` X310 transport
path. Both native `61.44 MSps` and `-E` `46.08 MSps` variants overflow and abort
before phone validation can start. A real 106-PRB retry should move the X310 to
a 10 GbE-capable host/NIC path or a host already validated for this sample-rate
load.

## Follow-up: 51 PRB RACH Tuning

The DU was returned to 51 PRBs after the 106-PRB blocker. Several RACH-related
settings were tested:

- `prach_dtx_threshold = 200`: stable, no UHD overflow and no false PRACH flood,
  but no UE attach evidence appeared during the observation window.
- `prach_dtx_threshold = 150`: PRACH returned, but every attempt stopped at
  `WAIT_Msg3`; the DU generated Msg2/RAR but never decoded Msg3.
- `min_rxtxtime = 10`: moved Msg3 scheduling later but did not solve the Msg3
  failure.
- Reduced RX gain (`att_rx = 12`) made the false/multiple-PRACH behavior worse.
- Increased DL/UL power nudges did not produce RRC or NAS progression.

Representative tuned 51-PRB failure:

```text
Generating RA-Msg2 DCI
Scheduling retransmission of Msg3
RA failed at state WAIT_Msg3 (Reached msg3 max harq rounds)
success_marker_count=0
```

Final live state left running:

```text
dl_carrierBandwidth = 51
ul_carrierBandwidth = 51
initialDLBWPlocationAndBandwidth = 13750
initialULBWPlocationAndBandwidth = 13750
min_rxtxtime = 10
prach_dtx_threshold = 200
att_tx = 3
att_rx = 0
Actual RX sample rate: 30.720000MSps
RU 0 rf device ready
received F1 Setup Response from CU gNB-CU-MINIPC
Configured PWS/SIB8 SI segment 0
```

Phone attach, internet, and handset-side PWS reception remain unverified. The
next useful test requires a synchronized handset action: confirm APN `oai`,
toggle Airplane Mode beside the antenna, and watch whether the DU produces a
single strong PRACH that advances past Msg3.

## Follow-up: Low-Rate X310 Attempts

After the native 51-PRB run showed persistent late markers and Msg3 failures,
the DU was tested with `-E` to reduce the X310 host sample rate from
`30.72 MSps` to `23.04 MSps`.

Low-rate X310 command shape:

```text
./nr-softmodem -O /tmp/oai-tui-gnb-minipc-ethernet-runtime.conf \
  --log_config.global_log_level info -E --thread-pool 1,2,3
```

This improved transport stability:

```text
Actual RX sample rate: 23.040000MSps
RU 0 rf device ready
overflow_problem_count=0
```

RACH threshold sweep:

```text
prach_dtx_threshold=120: PRACH storm remained; Msg2 generated, no Msg3.
prach_dtx_threshold=160: fewer PRACH attempts; Msg2 generated, no Msg3.
prach_dtx_threshold=180: quiet window unless isolated PRACH appears; still no Msg3/RRC.
```

Representative threshold-180 result:

```text
RAPROC ... preamble 26 ... timing_offset = 1
Generating RA-Msg2 DCI
Scheduling retransmission of Msg3
RA failed at state WAIT_Msg3
success_marker_count=0
```

`--continuous-tx` was also tested as a USRP/OAI timing workaround. It made the
run worse:

```text
--continuous-tx
overflow_problem_count=3078
success_marker_count=0
```

Final low-rate state left running:

```text
dl_carrierBandwidth = 51
ul_carrierBandwidth = 51
absoluteFrequencySSB = 641280
dl_absoluteFrequencyPointA = 640656
prach_dtx_threshold = 180
Actual RX sample rate: 23.040000MSps
RU 0 rf device ready
Configured PWS/SIB8 SI segment 0
```

Conclusion: lowering the sample rate improves X310 transport stability, but it
does not by itself solve attach. The remaining blocker is still the access RF
random-access path: the DU either suppresses noise-like PRACH or generates Msg2
for isolated PRACH attempts but never decodes Msg3. A clean synchronized phone
toggle beside the antenna is required to distinguish a real handset attempt
from the noise-like PRACH signatures observed in unattended windows.
