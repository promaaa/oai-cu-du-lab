# X310 CAT8 Transport And F1 Setup Check

## Objective

Check whether the new CAT8 cable changed the usable X310 access-radio
transport for `serber-minipc` and whether the X310 access cell can be brought
up with `serber-firecell` as 5GC/CU.

## Date

2026-07-06, observed from the lab hosts around `13:25` to `13:40`
Asia/Riyadh.

## Topology Observed

- Core/CU: `serber-firecell` at `10.76.170.38`
- DU/radio: `serber-minipc` at `10.76.170.40`
- X310 address: `192.168.10.3`
- X310 host interface: `serber-minipc` `enp4s0`
- F1 transport selected in TUI: Ethernet
- UE target: Nothing Phone, APN/DNN `oai`

The `serber-firecell` SSH alias in the local shell resolved to
`serber-minipc`, so direct `serber@10.76.170.38` was used for firecell
evidence.

## Physical Transport Result

The CAT8 cable did not change the negotiated X310 radio link speed. The
X310-facing MiniPC NIC is still a Realtek gigabit interface:

```text
serber-minipc enp4s0
driver: r8169
bus-info: 0000:04:00.0
Supported link modes: 10/100/1000baseT
Speed: 1000Mb/s
Duplex: Full
Port: Twisted Pair
Link detected: yes
MTU: 9000
tx_errors: 0
rx_errors: 0
rx_missed: 0
```

`ip route get 192.168.10.3` still routes the X310 over `enp4s0`:

```text
192.168.10.3 dev enp4s0 src 192.168.10.1
```

Firecell also only showed a 1 GbE physical Ethernet link on `enp6s0`; the
10 Gb/s value seen on `oai-cn5g-minipc` is the Docker bridge, not a physical
X310 transport.

Conclusion: do not retry 106 PRB as if CAT8 itself solved the old blocker.
The host and X310 path still negotiates at 1 GbE.

## X310 Discovery

UHD discovery on `serber-minipc` found the X310:

```text
Device Address:
    serial: 32B50AA
    addr: 192.168.10.3
    fpga: HG
    product: X310
    type: x300
Maximum frame size: 8000 bytes
FPGA Version: 39.3
FPGA git hash: 8e780be
Clock sources: internal, external, gpsdo
```

The installed UHD benchmark binaries could not provide a decisive `sc8`
transport benchmark: both the packaged and local benchmark reported:

```text
Cannot find a conversion routine
Input format: sc8_chdr
Output format: fc32
```

This is a benchmark-tool limitation, not a PASS or FAIL for OAI.

## Runtime Repairs Made

Two operator-path issues were fixed or restored before relaunch:

1. `scripts/oai-lab-tui` now passes the discovered DU SSH target into
   `ensureUpfRoutingAndNat()`. This avoids falling back to direct
   `serber@10.76.170.40`, which timed out locally even though the
   `serber-minipc` alias worked.
2. On `serber-minipc`, `/home/serber/monolithic` had been removed while
   `/home/serber/cu-du/source/openairinterface5g/cmake_targets` still pointed
   there. A symlink was restored:

```text
/home/serber/monolithic -> /home/serber/_cleanup_quarantine/20260629/home-serber/monolithic
```

The restored binary reports the pinned rollback build banner:

```text
Version: Branch: HEAD Abrev. Hash: 102965a669
```

## 51 PRB Runtime Config

The MiniPC DU runtime config used the known X310 51 PRB values:

```text
absoluteFrequencySSB = 641280;
dl_absoluteFrequencyPointA = 640656;
dl_carrierBandwidth = 51;
ul_carrierBandwidth = 51;
initialDLBWPlocationAndBandwidth = 13750;
initialULBWPlocationAndBandwidth = 13750;
sdr_addrs = "type=x300,addr=192.168.10.3,recv_frame_size=8000,send_frame_size=8000,otw=sc8";
clock_src = "internal";
```

The TUI reached:

- X310 preflight discovery;
- split core container startup;
- phone subscriber provisioning;
- UPF MSS clamping;
- CU runtime config generation;
- DU runtime config generation;
- CU process startup;
- DU process startup attempt.

Jumbo MTU over the firecell/minipc F1 path failed and the TUI fell back to MSS
clamping:

```text
ping -s 8972 -M do: 3 packets transmitted, 0 received, +3 errors
Path MTU test FAILED
```

## F1 Setup Blocker

The fresh X310 DU did not reach X310 RF-ready state. It stopped at F1 setup.

CU-side evidence from a clean run:

```text
Received F1 Setup Request from gNB_DU 3585 (gNB-CU-MINIPC)
Accepting DU 3585 (gNB-CU-MINIPC), sending F1 Setup Response
Received F1 Setup Request from gNB_DU 3585 (gNB-CU-MINIPC)
gNB-DU ID: existing DU gNB-CU-MINIPC already has ID 3585, rejecting requesting gNB-DU
CU_send_F1_SETUP_FAILURE
```

DU-side evidence:

```text
DU_send_F1_SETUP_REQUEST
the CU reported F1AP Setup Failure, is there a configuration mismatch?
```

A manual DU launch without `sudo` showed the same accept-then-duplicate-reject
pattern, so this was not only the TUI `sudo setsid` wrapper.

## UE, PWS, And Throughput Outcome

Not passed.

The 2026-07-06 run did not reach:

- `Actual RX sample rate`;
- `RU 0 rf device ready`;
- `RRCSetup`;
- `InitialUEMessage`;
- AMF registration;
- PDU session establishment;
- phone internet;
- phone-side PWS/SIB8 reception.

No phone PASS is claimed.

## Conclusion

This run proves a hard blocker, not a full PASS.

The new CAT8 cable did not change the X310 transport rate because the active
MiniPC/X310 NIC path is still 1 GbE. Therefore, 106 PRB remains physically
blocked until the X310 is connected through a host/NIC path that negotiates at
10 GbE or better.

The 51 PRB X310 path is still the right fallback direction, but the current
run stops earlier than the previous Msg3 boundary because F1 setup is accepted
once and then rejected as a duplicate DU ID. Resolve that F1 duplicate setup
behavior before spending more time on phone attach, PWS, or throughput.

## Rollback And Known State

Softmodem processes were stopped on both firecell and minipc after the failed
run. The B210 Ethernet rollback baseline remains the demo target for phone
attach, internet, and PWS/SIB8 proof.

For demo rollback, restore the B210 DU config outside Git if needed, then run:

```bash
./scripts/oai-lab-tui --start-ethernet
```

Validate F1 setup, phone registration, phone-side PWS/SIB8, and user-plane
internet before claiming rollback health.

## Next Actions

1. Do not test 106 PRB on the present MiniPC/X310 1 GbE path.
2. Move the X310 to a real 10 GbE-capable host/NIC path, or install a verified
   10 GbE NIC/transceiver path on `serber-minipc`.
3. Before the next 51 PRB phone window, debug why the DU/CU exchange produces
   a duplicate F1 setup request for DU ID `0xe01`.
4. After F1 setup is stable, repeat the 51 PRB synchronized phone window:
   phone beside antenna, APN `oai`, Airplane Mode toggle, DU/CU/AMF log window,
   PWS observation, and throughput proof.
