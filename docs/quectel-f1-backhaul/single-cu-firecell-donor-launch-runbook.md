# Caged CU/DU Split With Quectel 5G Backhaul And Monolithic Donor Runbook

**Date updated**: 2026-06-07
**Scenario**: `serber-minipc` DU and access USRP B210 inside a Faraday cage; Quectel modem, `serber-firecell`, and firecell donor USRP outside the cage.
**Target result**: one OAI 5GC, one OAI CU, one monolithic firecell donor gNB for Quectel, and one caged minipc access DU whose F1 backhaul crosses WireGuard-over-Quectel.

This runbook is the supported Quectel backhaul procedure. It intentionally uses
the monolithic donor gNB on `serber-firecell`; the failed local-F1 donor-DU path
is deprecated.

Do not store passwords, WireGuard private keys, SIM Ki/OPc, raw subscriber material, or unsanitized packet captures in this repository.

---

## 1. Target Architecture

```text
serber-firecell
  one OAI 5GC
  one OAI CU
  monolithic firecell donor gNB + outside USRP
    NR Cell ID 22345678, PCI 1, TAC 2
    serves only the Quectel modem; no F1 path
  wg-quectel-f1: 10.250.0.1/30

Quectel RM500Q-GL outside cage
  attaches only to firecell monolithic donor gNB
  PDU session on serber-minipc wwan0
  WireGuard outer UDP on wwan0

serber-minipc
  access DU + B210 serial 8002816 inside cage
    DU ID 0xe01, gNB ID 0xe00, NR Cell ID 12345678, PCI 0, TAC 1
    F1-C/F1-U: 10.250.0.2 -> 10.250.0.1 over wg-quectel-f1

Nothing Phone inside cage
  attaches only to minipc access DU
```

The important fix is avoiding same-cell recursion. The Quectel modem must attach
only through the firecell monolithic donor gNB. The minipc B210 remains the access cell for
the Nothing Phone and is never used for backhaul.

For phone user-plane validation, configure the commercial UE subscriber outside
Git, for example in ignored `conf/local/lab.env` as `PHONE_IMSI=<phone-imsi>`.
The TUI seeds this subscriber with sanitized evidence during caged launch and
validate flows when `PHONE_IMSI` is present.

### Launch Sequence

```bash
./scripts/quectel-f1-backhaul/05_generate_quectel_f1_configs.sh
./scripts/quectel-f1-backhaul/05_start_core.sh
# Start the firecell monolithic donor gNB from the TUI or the validated lab command.
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh
./scripts/quectel-f1-backhaul/03_setup_wireguard_minipc.sh
./scripts/quectel-f1-backhaul/02_setup_wireguard_firecell.sh
./scripts/quectel-f1-backhaul/04_validate_backhaul_path.sh
./scripts/quectel-f1-backhaul/06_start_cu_quectel.sh
./scripts/quectel-f1-backhaul/07_start_du_quectel.sh
./scripts/quectel-f1-backhaul/08_validate_f1.sh
```

The TUI path is:

```bash
./scripts/oai-lab-tui --start-caged-quectel
```

### PASS Gate

Do not claim PASS unless packet captures prove all of the following:

- firecell monolithic donor gNB is in service and the Quectel camps on PCI `1` / TAC `2`;
- minipc access DU F1-C SCTP is on `wg-quectel-f1`;
- minipc access DU F1-U UDP/2153 is on `wg-quectel-f1` during phone traffic;
- WireGuard outer UDP is on `wwan0`;
- Ethernet/WiFi do not carry minipc access DU F1.

### Rollback

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```

Rollback stops the minipc access DU, CU, and monolithic donor gNB by exact
config path, preserves management SSH, removes stale Quectel routes, and restarts
the Ethernet CU/DU baseline.

## 2. Historical Values From The Earlier Caged Run

The remaining sections retain evidence from the earlier monolithic-donor bring-up.
Use them for troubleshooting values only. The monolithic-donor evidence below is
the basis for the current supported launch procedure.

### Host Reachability Used

| Host | Management path used | Notes |
|---|---:|---|
| `serber-firecell` | `serber@10.76.170.38` | Core, CU, outside monolithic donor gNB |
| `serber-minipc` | `serber@10.85.168.144` | WiFi management worked during this run |
| `serber-minipc` Ethernet | `10.76.170.109/25` on `enp4s0` | It was not at the older `10.76.170.100` address |

Ethernet/WiFi were used only for SSH/control/diagnostics. F1 traffic was bound to `wg-quectel-f1`.

---

## 2. Live Values From The Successful Run

| Item | Value |
|---|---|
| Quectel modem | RM500Q-GL |
| QMI device | `/dev/cdc-wdm0` |
| AT ports present | `/dev/ttyUSB0` through `/dev/ttyUSB4` |
| Quectel data interface | `wwan0` |
| Quectel PDU IP | `10.0.0.3/29` |
| Quectel PDU gateway | `10.0.0.4` |
| APN | `oai` |
| Firecell bridge route to Quectel | `10.0.0.3/32 via 192.168.71.134 dev oai-cn5g-minipc` |
| WireGuard tunnel | `wg-quectel-f1` |
| Firecell WG IP | `10.250.0.1/30` |
| Minipc WG IP | `10.250.0.2/30` |
| Firecell WG listen port | `51821` |
| Minipc WG endpoint | `192.168.71.129:51821` via `wwan0` |
| Access USRP | B210 serial `8002816` |
| Access cell | PLMN `001/01`, PCI `0`, ARFCN `641280`, band `n78` |
| Donor cell | PLMN `001/01`, PCI `1`, ARFCN `641280`, band `n78`, 51 PRB |
| User-reported throughput | About `15 Mb/s` |

---

## 3. Preflight

Run these checks before launching. The TUI should fail closed if any required item is missing.

### 3.1 Firecell Core And RAN Process Check

```bash
ssh serber@10.76.170.38 '
hostname
ip -4 -br addr
docker ps --format "{{.Names}} {{.Status}}" | grep oai-cn5g-minipc || true
pgrep -a nr-softmodem || true
'
```

Expected core containers:

```text
oai-cn5g-minipc-oai-upf-1 healthy
oai-cn5g-minipc-oai-smf-1 healthy
oai-cn5g-minipc-oai-amf-1 healthy
oai-cn5g-minipc-oai-ausf-1 healthy
oai-cn5g-minipc-oai-udm-1 healthy
oai-cn5g-minipc-oai-udr-1 healthy
oai-cn5g-minipc-mysql-1 healthy
oai-cn5g-minipc-oai-nrf-1 healthy
oai-cn5g-minipc-oai-ext-dn-1 healthy
oai-cn5g-minipc-ims-1 healthy
```

### 3.2 Minipc Hardware Check

```bash
ssh serber@10.85.168.144 '
hostname
ip -br link
ip -4 -br addr
ls -l /dev/cdc-wdm* /dev/ttyUSB* 2>/dev/null || true
uhd_find_devices --args serial=8002816
pgrep -a nr-softmodem || true
'
```

Expected B210 evidence:

```text
Device Address:
    serial: 8002816
    product: B210
```

---

## 4. Start Or Verify Firecell Core

The successful run used the split core compose file on firecell:

```bash
ssh serber@10.76.170.38 '
cd /home/serber/cu-du-minipc/oai-cn5g-minipc
docker compose -f docker-compose-minipc.yaml up -d
docker ps --format "{{.Names}} {{.Status}}" | grep oai-cn5g-minipc
'
```

Verify the bridge addresses:

```bash
ssh serber@10.76.170.38 '
ip -4 addr show dev oai-cn5g-minipc
'
```

Expected:

```text
192.168.71.129/26
192.168.71.140/26
```

---

## 5. Generate Split CU/DU Configs

Generate the CU config bound to `10.250.0.1` and the minipc access DU
WireGuard-F1 config:

```bash
./scripts/quectel-f1-backhaul/05_generate_quectel_f1_configs.sh
```

Expected identity split:

```text
CU: binds F1-C/F1-U to 10.250.0.1 on wg-quectel-f1
minipc access DU: DU ID 0xe01, gNB ID 0xe00, NR Cell ID 12345678, PCI 0, TAC 1
minipc access radio: B210 serial 8002816
```

The minipc access DU F1 addresses must be:

```text
local_s_address/local_n_address: 10.250.0.2
remote_s_address/remote_n_address: 10.250.0.1
local_n_if_name: wg-quectel-f1
```

---

## 6. Start Quectel PDU Session On Minipc

The modem was plugged into minipc and exposed `/dev/cdc-wdm0` plus `wwan0`.

First check QMI state:

```bash
ssh serber@10.85.168.144 '
sudo qmicli -d /dev/cdc-wdm0 --device-open-proxy --wds-get-packet-service-status || true
sudo qmicli -d /dev/cdc-wdm0 --device-open-proxy --wds-get-current-settings || true
'
```

If disconnected, start the APN:

```bash
ssh serber@10.85.168.144 '
sudo ip link set wwan0 down || true
printf Y | sudo tee /sys/class/net/wwan0/qmi/raw_ip >/dev/null 2>&1 || true
sudo ip link set wwan0 up
sudo qmicli -d /dev/cdc-wdm0 --device-open-proxy \
  --wds-start-network="apn=oai,ip-type=4" \
  --client-no-release-cid
sleep 2
sudo qmicli -d /dev/cdc-wdm0 --device-open-proxy --wds-get-packet-service-status
sudo qmicli -d /dev/cdc-wdm0 --device-open-proxy --wds-get-current-settings
'
```

Successful current settings from the run:

```text
Connection status: connected
IPv4 address: 10.0.0.3
IPv4 subnet mask: 255.255.255.248
IPv4 gateway address: 10.0.0.4
IPv4 primary DNS: 1.1.1.1
MTU: 1500
```

Assign the live address and route the firecell WireGuard endpoint through `wwan0`:

```bash
ssh serber@10.85.168.144 '
sudo ip addr flush dev wwan0
sudo ip addr add 10.0.0.3/29 dev wwan0
sudo ip link set wwan0 up
sudo ip route replace 10.0.0.4 dev wwan0 src 10.0.0.3
sudo ip route replace 192.168.71.129/32 via 10.0.0.4 dev wwan0 src 10.0.0.3
ip -4 addr show dev wwan0
ip route get 192.168.71.129
'
```

Add the return route on firecell:

```bash
ssh serber@10.76.170.38 '
sudo ip route replace 10.0.0.3/32 via 192.168.71.134 dev oai-cn5g-minipc
ip route get 10.0.0.3
'
```

Expected firecell route:

```text
10.0.0.3 via 192.168.71.134 dev oai-cn5g-minipc src 192.168.71.129
```

---

## 7. Start WireGuard Over Quectel

Use existing local `/etc/wireguard/wg-quectel-f1.conf` files. They must route the firecell endpoint through the active Quectel gateway.

Minipc route hook must match the current PDU address:

```text
PreUp = ip route replace 192.168.71.129/32 via 10.0.0.4 dev wwan0 src 10.0.0.3
```

Firecell route hook must match the current Quectel PDU address:

```text
PostUp = ip route replace 10.0.0.3/32 via 192.168.71.134 dev oai-cn5g-minipc
```

Restart and validate both ends:

```bash
ssh serber@10.85.168.144 '
sudo systemctl restart wg-quick@wg-quectel-f1
sleep 2
sudo wg show wg-quectel-f1
ping -c 4 -W 2 10.250.0.1
'
```

```bash
ssh serber@10.76.170.38 '
sudo systemctl restart wg-quick@wg-quectel-f1
sleep 2
sudo wg show wg-quectel-f1
ping -c 4 -W 2 10.250.0.2
'
```

Observed validation:

```text
minipc -> firecell tunnel ping: 4/4 replies, 0% loss, about 18.5 ms average
firecell -> minipc tunnel ping: 4/4 replies, 0% loss, about 19.9 ms average
latest WireGuard handshake: fresh on both peers
```

---

## 8. Start Split CU On Firecell

Do not use a script that blindly kills all `nr-softmodem` processes on firecell.
Firecell intentionally runs both the CU and the monolithic donor gNB.

Working CU config:

```text
/home/serber/cu-du-minipc-backhaul/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc-quectel-backhaul.conf
```

Expected CU F1 bindings:

```text
F1-C: 10.250.0.1 -> 10.250.0.2 on wg-quectel-f1
F1-U: 10.250.0.1 -> 10.250.0.2 on wg-quectel-f1
N2/N3/core side: 192.168.71.129
```

Launch with the repository script. It stops only an existing CU using this exact
config path and leaves the donor gNB alone:

```bash
./scripts/quectel-f1-backhaul/06_start_cu_quectel.sh
```

Expected CU evidence:

```text
Received NGSetupResponse from AMF
F1AP_CU_SCTP_REQ / F1 setup activity for the minipc access DU
GTP-U / UDP 2153 initialization
```

---

## 9. Firecell Monolithic Donor GNB

The donor gNB should already be running before Quectel registration. It serves
only the Quectel modem and has no F1 path.

```bash
./scripts/oai-lab-tui --start-caged-quectel
```

Expected donor gNB evidence:

```text
Received NGSetupResponse from AMF
cell in service with PCI 1 and TAC 2
donor radio detected / synchronized
```

After the donor gNB is in service, reset/register the Quectel and start or verify
the PDU session:

```bash
./scripts/quectel-f1-backhaul/01_check_quectel_connectivity.sh
./scripts/quectel-f1-backhaul/02_validate_independent_donor.sh
```

---

## 10. Start Split DU On Minipc

Only start the DU after WireGuard tunnel ping passes. The DU uses the caged B210 as access-cell radio and binds F1 to the tunnel.

Working DU config:

```text
/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc-quectel-backhaul.conf
```

Expected DU F1 bindings:

```text
F1-C local: 10.250.0.2
F1-C remote CU: 10.250.0.1
F1-U local: 10.250.0.2 UDP/2153
```

Launch with the repository script. It stops only an existing minipc DU using this
exact config path:

```bash
./scripts/quectel-f1-backhaul/07_start_du_quectel.sh
```

Expected DU evidence:

```text
F1-C DU IPaddr 10.250.0.2, connect to F1-C CU 10.250.0.1, binding GTP to 10.250.0.2
DU_send_F1_SETUP_REQUEST
DU_handle_F1_SETUP_RESPONSE
received F1 Setup Response from CU gNB-CU-MINIPC
Detected Device: B210
Operating over USB 3
got sync
```

Expected CU follow-up evidence:

```text
Received F1 Setup Request from gNB_DU 3585
Accepting DU 3585
cell PLMN 001.01 Cell ID 12345678 is in service
```

---

## 10. Packet Validation

Run validation before claiming success. F1-C and F1-U must appear on the tunnel or Quectel path, not on management Ethernet/WiFi.

### 10.1 Minipc Captures

```bash
ssh serber@10.85.168.144 '
echo "=== minipc wg F1 ==="
sudo timeout 45 tcpdump -l -nni wg-quectel-f1 "sctp or udp port 2153" 2>/dev/null | head -n 30

echo "=== minipc wwan WireGuard outer ==="
sudo timeout 20 tcpdump -l -nni wwan0 "udp port 51821 or udp port 40016" 2>/dev/null | head -n 20

echo "=== minipc enp4s0 no F1 ==="
sudo timeout 12 tcpdump -l -nni enp4s0 "sctp or udp port 2153" 2>/dev/null | head -n 5

echo "=== minipc wlp3s0 no F1 ==="
sudo timeout 12 tcpdump -l -nni wlp3s0 "sctp or udp port 2153" 2>/dev/null | head -n 5
'
```

Observed F1-C proof:

```text
10.250.0.2 > 10.250.0.1: sctp [HB REQ]
10.250.0.1 > 10.250.0.2: sctp [HB ACK]
10.250.0.1 > 10.250.0.2: sctp [HB REQ]
10.250.0.2 > 10.250.0.1: sctp [HB ACK]
```

Observed Quectel outer proof:

```text
192.168.71.129.51821 > 10.0.0.3.40016: UDP
```

Observed management proof:

```text
No F1 packets matched on enp4s0 or wlp3s0 during validation windows.
```

### 10.2 Firecell Captures

```bash
ssh serber@10.76.170.38 '
echo "=== firecell wg F1 ==="
sudo timeout 45 tcpdump -l -nni wg-quectel-f1 "sctp or udp port 2153" 2>/dev/null | head -n 30

echo "=== firecell oai bridge WireGuard outer ==="
sudo timeout 20 tcpdump -l -nni oai-cn5g-minipc "host 10.0.0.3 and udp" 2>/dev/null | head -n 20

echo "=== firecell enp6s0 no F1 ==="
sudo timeout 12 tcpdump -l -nni enp6s0 "sctp or udp port 2153" 2>/dev/null | head -n 5
'
```

Observed firecell tunnel proof:

```text
10.250.0.2 > 10.250.0.1: sctp [HB REQ]
10.250.0.1 > 10.250.0.2: sctp [HB ACK]
10.250.0.1 > 10.250.0.2: sctp [HB REQ]
10.250.0.2 > 10.250.0.1: sctp [HB ACK]
```

### 10.3 UE And F1-U Proof

After the Nothing Phone attaches to the caged minipc access cell, generate traffic and capture F1-U:

```bash
ssh serber@10.85.168.144 '
sudo timeout 90 tcpdump -l -nni wg-quectel-f1 "udp port 2153" 2>/dev/null
'
```

```bash
ssh serber@10.76.170.38 '
sudo timeout 90 tcpdump -l -nni wg-quectel-f1 "udp port 2153" 2>/dev/null
'
```

Also watch logs:

```bash
ssh serber@10.85.168.144 '
tail -n 400 /tmp/du-minipc-quectel-backhaul.log | grep -Ei "PRACH|RNTI|Msg[1234]|RA-|UE|F1-U|GTP|2153|RRC" | tail -n 120
'
```

```bash
ssh serber@10.76.170.38 '
tail -n 500 /tmp/cu-minipc-quectel-backhaul.log | grep -Ei "UE|RNTI|RRC|F1-U|GTP|PDU|NAS|INITIAL|Setup" | tail -n 160
docker logs --since 5m oai-cn5g-minipc-oai-amf-1 2>&1 | grep -Ei "imsi|registration|pdu|initial|ue|001010" | tail -n 120
'
```

For the successful phone test, the user reported about `15 Mb/s`. Record fresh F1-U `UDP/2153` packet lines in the final experiment log whenever possible.

---

## 11. Faraday Cage Interpretation

The physical placement is part of the validation:

- `serber-minipc`, its B210, and the Nothing Phone were inside the Faraday cage.
- Quectel, `serber-firecell`, and the firecell donor USRP were outside.
- Firecell donor cell used PCI `1`.
- Minipc access DU used PCI `0`.

Therefore, when the phone inside the cage is served after the minipc DU is in service, it is being served by the caged minipc access cell, not by the outside firecell donor.

For TUI display, show donor and access cells as separate roles even though both use PLMN `001/01` and ARFCN `641280`.

---

## 12. Rollback

Rollback should preserve management access.

### Stop Minipc Access DU

```bash
ssh serber@10.85.168.144 '
conf=/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc-quectel-backhaul.conf
ps -eo pid=,comm=,args= | awk -v conf="$conf" '\''$2 == "nr-softmodem" && index($0, conf) > 0 { print $1 }'\'' | xargs -r sudo kill -9
'
```

### Stop Firecell Split CU And Donor DU

Identify both firecell roles by config path:

```bash
ssh serber@10.76.170.38 '
for conf in \
  /home/serber/cu-du-minipc-backhaul/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc-quectel-backhaul.conf \
  /home/serber/cu-du-minipc-backhaul/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-du-firecell-donor-local-f1.conf
do
  ps -eo pid=,comm=,args= | awk -v conf="$conf" '\''$2 == "nr-softmodem" && index($0, conf) > 0 { print $1 }'\'' | xargs -r sudo kill -9
done
'
```

### Stop WireGuard

```bash
ssh serber@10.85.168.144 'sudo systemctl stop wg-quick@wg-quectel-f1 || true'
ssh serber@10.76.170.38 'sudo systemctl stop wg-quick@wg-quectel-f1 || true'
```

### Restore Ethernet/WiFi Baseline

Preferred rollback:

```bash
./scripts/quectel-f1-backhaul/09_rollback_to_ethernet.sh
```

---

## 13. TUI Automation Notes

The TUI should model this as a state machine with explicit gates:

1. **Hardware gate**: B210 serial `8002816` visible on minipc; Quectel QMI device and `wwan0` visible.
2. **Core gate**: firecell split core containers healthy.
3. **Donor gate**: firecell monolithic donor gNB in service with PCI `1` and TAC `2`.
4. **Quectel gate**: QMI PDU connected and `wwan0` has IPv4 settings.
5. **Route gate**: minipc route to `192.168.71.129` via Quectel gateway; firecell route back to Quectel PDU IP.
6. **WireGuard gate**: fresh handshake and bidirectional ping between `10.250.0.1` and `10.250.0.2`.
7. **CU gate**: CU log shows F1 SCTP listener on `10.250.0.1` and GTP-U on `10.250.0.1:2153`.
8. **DU gate**: DU log shows F1 setup response and B210 sync.
9. **Packet gate**: F1-C SCTP visible on `wg-quectel-f1`; WireGuard outer UDP visible on `wwan0`; no F1 on management interfaces.
10. **UE/F1-U gate**: phone attach and `UDP/2153` visible on `wg-quectel-f1`.

Useful TUI warnings:

- Do not run helpers that kill all `nr-softmodem` processes on firecell while the CU/donor-gNB pair is running.
- Do not assume minipc Ethernet is `10.76.170.100`; discover management IP and interface each run.
- Do not assume the Quectel PDU IP is stable; parse QMI current settings and update routes/hooks accordingly.
- ICMP to public internet can fail even when TCP/HTTP and private OAI routing work.
- Same-cell Quectel backhaul is recursive and unstable; the Quectel modem must use the firecell monolithic donor gNB or another non-recursive donor path.

---

## 14. Minimal Success Criteria

Mark the TUI scenario **PASS** only when all of these are true:

- F1-C SCTP is visible on `wg-quectel-f1`.
- WireGuard outer UDP is visible on `wwan0` between firecell and Quectel.
- F1-U `UDP/2153` is visible on `wg-quectel-f1` during phone traffic.
- Management Ethernet/WiFi do not carry F1-C or F1-U.
- CU/DU F1 association remains stable.
- The Nothing Phone is served by the caged minipc access cell.
- Rollback commands remain available over management SSH.

The 2026-06-04 launch reached stable CU/DU association and user-reported about `15 Mb/s`. For a formal final report, save fresh sanitized tcpdump lines for F1-U `UDP/2153` during the speed test.
