# Prompt: Make the X310 access-cell transport work with serber-minipc and serber-firecell

You are working in `/Users/promaa/Documents/oai-cu-du-lab` on `main`.

The user bought a CAT8 Ethernet cable advertised as `40Gbps` and wants the USRP X310 access-cell path to work with `serber-minipc` and `serber-firecell`.

Important framing: **do not assume the cable itself gives 40Gbps**. CAT8 is only the passive cable. The actual usable rate depends on both NICs, switch ports, transceivers/adapters, and the X310 Ethernet interface. The previous blocker was that the X310 was reachable from `serber-minipc` only over `enp4s0` at `1000Mb/s`. A new cable only fixes this if the host and X310 path now negotiates above 1GbE, ideally 10GbE or better.

## Read first

- `AGENTS.md`
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `experiments/20260625_x310_51prb_access_cell_verification.md`
- `prompts/20260625_usrp_x310_migration_51prb_prompt.md`
- `/Users/promaa/Documents/kaust-5G-research/docs/Presentation/Research Progress Report 19.md`

## Immutable rules

- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw logs, raw packet captures, or subscriber dumps.
- Preserve rollback: the known-good B210 Ethernet/Quectel access-cell path remains the rollback baseline for demos that need phone attach, internet, and PWS reception.
- Do not claim PASS without synchronized evidence: DU/CU logs, negotiated link speed, packet placement, UE registration state, throughput, and phone-side PWS observation.
- Keep generated runtime configs out of Git.
- If you make durable repo changes, keep them small and feature-separated. OAI source stays external and pinned by commit.
- Work directly on `main`; do not create a branch unless the user explicitly asks.

## Known state before this prompt

Previous X310 work proved:

- X310 was detected at `192.168.10.3`.
- `serber-minipc` used `enp4s0` for the X310 radio network.
- Old negotiated X310 link was only `1000Mb/s`.
- 51 PRB native X310 at `30.72 MSps` could reach:
  - CU/AMF up,
  - F1-C associated,
  - DU received PWS/SIB8 warning,
  - X310 RF ready.
- 51 PRB did **not** complete phone attach:
  - PRACH detected,
  - Msg2/RAR generated,
  - Msg3 not decoded,
  - no `RRCSetup`, `InitialUEMessage`, NAS registration, PDU session, internet, or phone-side PWS proof.
- 106 PRB on the old 1GbE path failed:
  - native `61.44 MSps`: immediate `ERROR_CODE_OVERFLOW`;
  - `-E` `46.08 MSps`: immediate overflow and RFNoC timeout.
- Low-rate 51 PRB with `-E` at `23.04 MSps` improved UHD stability but still did not solve attach.

## Goal

Make the X310 access-cell configuration work end-to-end with:

- `serber-firecell`: 5GC + CU,
- `serber-minipc`: DU + X310 access radio,
- Nothing Phone: commercial UE with APN/DNN `oai`,
- PWS/SIB8 emergency alert reception,
- user-plane internet and throughput evidence.

The preferred target is a stable X310 configuration that can run either:

1. **106 PRB** if the new physical transport truly supports the required X310 sample rate, or
2. **51 PRB** if 106 PRB remains physically blocked but 51 PRB can be made to attach and pass phone/PWS/user-plane validation.

## Stage 1: Prove the new physical transport

Before changing OAI config, identify what the CAT8 cable is actually connecting:

- Is it between `serber-minipc` and the X310?
- Is it between `serber-minipc` and `serber-firecell`?
- Is there a switch in between?
- Are there 10G/25G/40G NICs or only 1GbE NICs?
- Does the X310 side use RJ45, SFP+, or an adapter?

Run and record sanitized outputs:

```bash
ssh serber-minipc 'hostname; date -Is; ip -br addr; ip -d link; lspci | grep -Ei "ethernet|network"; ethtool enp4s0; ethtool -S enp4s0 | grep -Ei "error|drop|miss|over|timeout"'
ssh serber-firecell 'hostname; date -Is; ip -br addr; ip -d link; lspci | grep -Ei "ethernet|network"; ethtool <firecell-f1-iface>'
ssh serber-minipc 'uhd_find_devices; uhd_usrp_probe --args "addr=192.168.10.3" | grep -Ei "X310|FPGA|Maximum frame|link|Mboard|Radio"'
```

If `ethtool enp4s0` still reports `Speed: 1000Mb/s`, **do not retry 106 PRB as if the cable solved the blocker**. Record that the cable did not change the negotiated X310 transport rate, then focus on 51 PRB attach or move the X310 to a host/NIC path that negotiates at 10GbE.

If a new high-speed NIC appears, discover its interface name and IP plan. Do not overwrite working management or F1 routes. Add a temporary X310-facing address only if needed, for example:

```bash
sudo ip addr add 192.168.10.1/24 dev <x310-high-speed-iface>
sudo ip link set <x310-high-speed-iface> mtu 9000 up
ip route get 192.168.10.3
ethtool <x310-high-speed-iface>
```

## Stage 2: Prove X310 transport independently of OAI

Use UHD-level tests before relaunching OAI:

```bash
ssh serber-minipc 'uhd_find_devices --args "addr=192.168.10.3"'
ssh serber-minipc 'uhd_usrp_probe --args "addr=192.168.10.3"'
```

If available, run `benchmark_rate` or the local UHD benchmark equivalent for the target rates:

- 51 PRB native: `30.72 MSps`;
- 51 PRB `-E`: `23.04 MSps`;
- 106 PRB `-E`: `46.08 MSps`;
- 106 PRB native: `61.44 MSps`.

Record whether there are `O`, `U`, dropped packets, sequence errors, or timeout errors. If standalone UHD cannot sustain the target rate, OAI will not pass either.

## Stage 3: Restore a known-clean X310 51 PRB baseline

Before trying 106 PRB again, get the X310 back to a stable 51 PRB baseline:

DU config path on minipc:

```text
/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf
```

Known X310 51 PRB values:

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

Start with:

```bash
./scripts/oai-lab-tui --start-ethernet
```

Then check:

```bash
ssh serber-minipc 'grep -aE "Actual RX sample rate|Actual TX sample rate|RU 0 rf device ready|ERROR_CODE|overflow|problem receiving|F1 Setup|Configured PWS|RAPROC|RRCSetup|InitialUEMessage" /tmp/oai-du-ethernet.log | tail -n 200'
ssh serber-firecell 'grep -aE "Accepting DU|F1 Setup|InitialUEMessage|Registration|PDU Session|UE Context|releasing DU" /tmp/oai-cu-ethernet.log | tail -n 200'
```

Expected machine-side minimum:

- `Actual RX sample rate: 30.720000MSps` for native 51 PRB, or `23.040000MSps` if using `-E`;
- `RU 0 rf device ready`;
- CU accepts DU;
- PWS/SIB8 configured;
- no UHD overflow.

## Stage 4: Retry 106 PRB only if the link really supports it

Only do this if Stage 1/2 proves a high-speed X310 path.

Change DU values:

```text
dl_carrierBandwidth = 106;
ul_carrierBandwidth = 106;
initialDLBWPlocationAndBandwidth = 28875;
initialULBWPlocationAndBandwidth = 28875;
absoluteFrequencySSB = 641280;
dl_absoluteFrequencyPointA = 640656;
```

First try 106 PRB with `-E`, because it is less demanding:

```text
Expected sample rate: 46.080000MSps
```

Only then try native:

```text
Expected sample rate: 61.440000MSps
```

Do not continue if either variant prints:

```text
ERROR_CODE_OVERFLOW
problem receiving samples
RfnocError: OpTimeout
```

If 106 PRB fails but 51 PRB is stable, roll back to 51 PRB and continue attach work there.

## Stage 5: Phone attach validation

This must be synchronized with the handset.

Ask the user to:

1. Put the Nothing Phone beside the antenna.
2. Confirm APN/DNN is `oai`.
3. Toggle Airplane Mode on/off.
4. Watch for 5G bars.
5. Keep the phone in place until the log window ends.

During that exact window, collect:

```bash
ssh serber-minipc 'grep -aE "RAPROC|RA-RNTI|Msg2|Msg3|RA failed|RRCSetup|RRCReconfiguration|InitialUEMessage|PDU Session|DRB|ERROR_CODE" /tmp/oai-du-ethernet.log | tail -n 300'
ssh serber-firecell 'grep -aE "InitialUEMessage|Registration|5GMM|PDU Session|UE Context|DRB|GTP|releasing DU" /tmp/oai-cu-ethernet.log | tail -n 300'
ssh serber-firecell 'docker logs oai-cn5g-minipc-oai-amf-1 --since 5m 2>&1 | sed -E "s/(imsi-|supi-)[0-9]+/\\1<redacted>/Ig; s/[0-9]{10,}/<redacted>/g" | tail -n 200'
```

PASS requires:

- phone shows 5G service or equivalent registered state;
- DU/CU logs show progression beyond Msg3 into RRC/NGAP;
- AMF shows UE registration;
- PDU session established;
- phone internet works;
- phone receives PWS/SIB8;
- sanitized throughput evidence is recorded.

Do not claim PASS for F1/PWS scheduling alone.

## Stage 6: Evidence and rollback

Create a new experiment report under `experiments/`, for example:

```text
experiments/YYYYMMDD_x310_high_speed_transport_and_attach.md
```

Include:

- exact cable/topology used;
- negotiated link speeds from `ethtool`;
- NIC/interface names and MTU;
- UHD/X310 discovery and FPGA version;
- OAI commit and binary banner;
- final DU config values;
- F1-C packet placement;
- X310 sample rate and overflow/drop result;
- phone attach result;
- PWS result;
- throughput result;
- rollback procedure.

Keep raw captures/logs out of Git. Commit only small sanitized excerpts.

Rollback target:

- restore B210/Ethernet or the last known X310 51 PRB fallback config;
- run `./scripts/oai-lab-tui --start-ethernet`;
- verify CU/DU F1, PWS/SIB8, and, if demo-critical, phone attach/internet on the known-good B210 path.

## Definition of done

Done means one of:

1. **Full PASS:** X310 access cell works end-to-end with phone registration, internet, and PWS/SIB8 evidence; or
2. **Hard blocker:** link speed, UHD benchmark, OAI logs, and sanitized evidence prove why the new CAT8 setup cannot sustain the required X310 sample rate or why attach still stops at Msg3.

In either case, leave the lab in a known state and document the exact next action.
