# Prompt: Move the X310 access-cell test to oai-pc for a real high-speed NIC path

You are working in `/Users/promaa/Documents/oai-cu-du-lab` on `main`.

The current MiniPC/X310 path is blocked at 1 GbE. The user wants to test a
better host path using either `serber-firecell` or `oai-pc`, with SSH access
kept through Wi-Fi while the single Ethernet port is repurposed for the X310.

## Decision from the 2026-07-06 discovery pass

Use `oai-pc` as the candidate host to unplug from Ethernet and cable to the
X310, **not `serber-firecell`**.

Reason:

- `serber-firecell` only showed an Intel I225-V Ethernet controller:
  `10/100/1000/2500baseT`, currently negotiated at `1000Mb/s`.
- `serber-firecell` Wi-Fi interfaces were present but unavailable/not
  associated, so unplugging its Ethernet would likely cut SSH access.
- `serber-firecell` is also the active 5GC/CU host and should stay stable for
  rollback/core duties.
- `oai-pc` is the historical powerful DU candidate, and its current DNS name
  resolves to a live SSH endpoint at `10.76.170.24`. Password SSH as
  `oai@oai-pc.kaust.edu.sa` is known to work from the user's terminal. The
  password must be supplied out-of-band by the operator and must not be written
  into this repository, scripts, prompts, shell history, or logs.

## Read first

- `AGENTS.md`
- `README.md`
- `docs/BASELINES.md`
- `docs/NETWORK.md`
- `docs/SECURITY.md`
- `audit/MIGRATION_MAP.md`
- `experiments/20260706_x310_cat8_transport_and_f1_setup.md`
- `experiments/20260625_x310_51prb_access_cell_verification.md`

## Immutable rules

- No secrets in Git: no UE `Ki`, `OPc`, passwords, tokens, private keys, raw
  logs, raw packet captures, or subscriber dumps.
- Preserve rollback: the B210 Ethernet split baseline remains the demo
  fallback for phone attach, internet, and PWS/SIB8.
- Do not claim PASS without synchronized evidence: negotiated link speed, UHD
  transport test, CU/DU logs, UE registration, PDU session, throughput, and
  phone-side PWS observation.
- Do not unplug or readdress any host until SSH over the non-Ethernet path is
  proven in the same session.
- Keep generated runtime configs out of Git.
- Work directly on `main`; do not create a branch unless explicitly requested.

## Known facts collected on 2026-07-06

### serber-firecell

Direct target used for reliable inventory:

```bash
ssh serber@10.76.170.38
```

Observed:

```text
hostname: serber-firecell
enp6s0: 10.76.170.38/25 and 192.168.10.1/24
Ethernet controller: Intel I225-V
Supported link modes: 10/100/1000/2500baseT
Current speed: 1000Mb/s
Port: Twisted Pair
MTU max: 9216
wlo1: wifi unavailable, not associated
wlx6c1ff7a3e383: USB wifi unavailable, not associated
```

Do not choose firecell as the X310 host for this migration unless Wi-Fi is
first brought up and a better NIC than I225-V is installed. It is not a 10 GbE
host based on the collected evidence.

### oai-pc

Current DNS from the operator machine:

```text
oai-pc.kaust.edu.sa -> 10.76.170.24
```

Reachability from the operator machine:

```text
ping oai-pc: reachable
TCP/22 on oai-pc: reachable
```

The older inventory address `10.76.170.90` did not respond during this pass.

SSH access note:

```text
ssh oai@oai-pc.kaust.edu.sa
Password authentication works from the user's terminal.
Do not store the password in Git or in helper scripts.
```

Before physical recabling, authenticate as `oai` and prove Wi-Fi management
access. If automation needs non-interactive SSH, ask the user to install an SSH
public key for `oai`; do not embed the password.

## Stage 1: Fix and prove oai-pc management over Wi-Fi

Use the `oai` account. Do not edit the user's normal `~/.ssh/known_hosts`
blindly. Use a temporary known-hosts file until the host identity is confirmed:

```bash
tmp=/tmp/oai_pc_known_hosts
ssh-keyscan -H oai-pc > "$tmp"
ssh -o UserKnownHostsFile="$tmp" -o StrictHostKeyChecking=yes oai@oai-pc.kaust.edu.sa 'hostname; id; date -Is'
```

Once authenticated, discover whether `oai-pc` has a Wi-Fi interface and whether
SSH can survive without Ethernet:

```bash
ssh oai@oai-pc.kaust.edu.sa 'hostname; date -Is; ip -br addr; ip route'
ssh oai@oai-pc.kaust.edu.sa 'lspci | grep -Ei "ethernet|network|wireless"; lsusb | grep -Ei "ethernet|realtek|intel|mediatek|wifi|wireless" || true'
ssh oai@oai-pc.kaust.edu.sa 'for i in $(ls /sys/class/net); do echo "## $i"; ip -d link show "$i" | sed -n "1,4p"; ethtool "$i" 2>/dev/null || true; done'
ssh oai@oai-pc.kaust.edu.sa 'command -v nmcli >/dev/null && nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status || true; command -v iwconfig >/dev/null && iwconfig 2>/dev/null || true; command -v iw >/dev/null && iw dev || true'
```

Required before unplugging Ethernet:

- Wi-Fi is connected and has a management IP.
- `ssh oai@<oai-pc-wifi-ip>` works from the operator machine.
- `ssh oai@<oai-pc-wifi-ip>` works after forcing the SSH target to the Wi-Fi
  IP, not the Ethernet IP.
- A second terminal can keep a persistent SSH session over Wi-Fi while the
  Ethernet cable is moved.

## Stage 2: Check whether oai-pc Ethernet is actually suitable for X310

Do not assume the PC has 10 GbE. Prove it:

```bash
ssh oai@oai-pc.kaust.edu.sa 'for i in $(ls /sys/class/net); do case "$i" in lo|docker*|br-*|veth*|wlan*|wl*) continue;; esac; echo "## $i"; ethtool "$i" 2>/dev/null | sed -n "1,80p"; done'
```

Proceed only if the target Ethernet NIC supports and negotiates at least
`10000Mb/s` when connected to the X310 or a known-good high-speed path. If it
only supports 1G or 2.5G, stop and document that it is not a solution for
106 PRB.

## Stage 3: Cable oai-pc Ethernet to X310

Only after Stage 1 proves Wi-Fi SSH:

1. Tell the user to unplug Ethernet from `oai-pc`.
2. Connect that Ethernet port to the X310 path.
3. Keep `serber-firecell` on Ethernet for 5GC/CU.
4. Configure a temporary X310-facing address on `oai-pc`:

```bash
ssh oai@<oai-pc-wifi-ip> 'sudo ip addr add 192.168.10.1/24 dev <x310-iface> 2>/dev/null || sudo ip addr replace 192.168.10.1/24 dev <x310-iface>; sudo ip link set <x310-iface> mtu 9000 up; ip route get 192.168.10.3; ethtool <x310-iface>'
```

If the X310 also has another port/IP available, record exactly which X310
interface is used. Do not overwrite working firecell/minipc management routes.

## Stage 4: Prove X310 transport with UHD before OAI

On `oai-pc`, check UHD tooling and X310 discovery:

```bash
ssh oai@<oai-pc-wifi-ip> 'command -v uhd_find_devices; command -v uhd_usrp_probe; uhd_find_devices --args "addr=192.168.10.3"; uhd_usrp_probe --args "addr=192.168.10.3" | grep -Ei "X310|FPGA|Maximum frame|Mboard|Radio|Clock|ip-addr"'
```

If `benchmark_rate` is available and supports the required OTW format, run
short tests before launching OAI:

```bash
ssh oai@<oai-pc-wifi-ip> 'for rate in 30.72e6 46.08e6 61.44e6; do echo "===== $rate ====="; timeout 20s benchmark_rate --args "addr=192.168.10.3,recv_frame_size=8000,send_frame_size=8000" --duration 5 --rx_rate "$rate" --tx_rate "$rate" --rx_otw sc8 --tx_otw sc8 --channels 0 2>&1 | tail -80; done'
```

If standalone UHD cannot sustain the target sample rate without `O`, `U`,
sequence errors, drops, or timeouts, OAI will not pass either.

## Stage 5: Decide the OAI role split

Preferred first architecture:

- `serber-firecell`: keep 5GC + CU.
- `oai-pc`: DU + X310 access radio.
- F1-C/F1-U: use Wi-Fi or a temporary routed management path only after packet
  placement is proven.

Important: If `oai-pc` Ethernet is consumed by X310, F1 cannot also use that
same Ethernet path. The agent must design F1 over the proven management/Wi-Fi
path, or add a second NIC. Do not silently strand the DU with radio transport
but no F1 path.

Copy the known X310 51 PRB DU config values first:

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

Try 106 PRB only after UHD proves a high-speed X310 path:

```text
106 PRB -E expected rate: 46.080 MSps
106 PRB native expected rate: 61.440 MSps
```

## Stage 6: Evidence and report

Create a sanitized experiment report under `experiments/`, for example:

```text
experiments/YYYYMMDD_oai_pc_x310_transport.md
```

Include:

- confirmed `oai-pc` SSH user `oai` and Wi-Fi management IP;
- proof that SSH survives over Wi-Fi before Ethernet is unplugged;
- `oai-pc` Ethernet NIC model, driver, supported modes, and negotiated speed;
- exact X310 cable/topology;
- `ip route get 192.168.10.3`;
- UHD/X310 probe;
- UHD benchmark results;
- OAI commit and binary banner if OAI is launched;
- final CU/DU/F1 path and packet placement;
- phone attach, PWS, and throughput results if reached;
- rollback procedure.

Definition of done is one of:

1. **Full PASS:** X310 access cell works end to end with phone registration,
   internet, throughput, and phone-side PWS/SIB8 evidence.
2. **Hard blocker:** evidence proves that `oai-pc` cannot provide a real
   high-speed X310 path or cannot maintain management/F1 while Ethernet is
   dedicated to the X310.

Do not claim PASS for link speed, F1 setup, or PWS scheduling alone.
