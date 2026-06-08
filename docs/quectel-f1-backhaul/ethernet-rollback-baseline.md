# Ethernet Rollback Baseline

**Phase**: 1  
**Date**: 2026-06-04
**Branch**: `main`  
**Status**: Confirmed canonical rollback baseline through TUI

---

## 1. Baseline Overview

| Property | Value |
|---|---|
| Baseline name | Ethernet CU/DU with SIB8 |
| Status | Confirmed working rollback target |
| OAI commit | `102965a669b9444857c27843ec8ce62780bf9d37` |
| Observed throughput | `19–23 Mb/s` |
| Rollback baseline | **Yes** (per ADR-004) |
| F1 transport | Ethernet (direct layer-2/layer-3 between hosts) |
| TUI evidence | `experiments/20260604_150124_ethernet_cu_du_rollback_start/` |

---

## 2. Host Roles

| Host | Role | Management IP | F1 Local IP | F1 Peer IP |
|---|---|---|---|---|
| `serber-firecell` | Core Network + CU | `10.76.170.38` | `10.76.170.38` | live minipc Ethernet IP |
| `serber-minipc` | DU + USRP B210 | discovered live | discovered live | `10.76.170.38` |

Latest TUI run discovered `serber-minipc` at `10.76.170.109` on `enp4s0`.
Do not assume the older `10.76.170.100` address for the TUI path.

---

## 3. Component Startup Order

The following startup sequence must be followed to restore Ethernet F1.

The supported operator path is:

```bash
./scripts/oai-lab-tui --start-ethernet
```

The TUI discovers the live minipc management IP and writes a runtime DU config:

```text
/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf
```

The source DU config remains unchanged.

### 3.1 On `serber-firecell` (Core Network + CU)

```bash
# 1. Start 5G Core Network (docker-compose)
cd /home/serber/cu-du-minipc-backhaul/source/oai-cn5g
docker-compose -f docker-compose-minipc.yaml up -d

# 2. Wait for AMF and other Core containers to be healthy
docker ps | grep oai-amf

# 3. Build and start CU
cd /home/serber/cu-du-minipc-backhaul/source/openairinterface5g
# Apply SIB8/PWS patch if not already applied
git checkout 102965a669b9444857c27843ec8ce62780bf9d37
# [patch apply step]
cmake Build/oai_gnb -j$(nproc)
./targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc.conf 2>&1 | tee /tmp/oai-cu-ethernet.log
```

**CU config file**: `gnb-cu-minipc.conf`  
**CU log file**: `/tmp/oai-cu-ethernet.log` (configurable via `conf/local/lab.env`: `CU_LOG`)

Key CU config parameters (from `conf/templates/ethernet-cu.yml`):

```
GNB_ID = 0xe00
GNB_NAME = gNB-CU-MINIPC
AMF_IP_ADDRESS = 192.168.71.132
F1_LOCAL_IP_ADDRESS = 10.76.170.38
F1_PEER_IP_ADDRESS = live minipc Ethernet IP
F1_PORT = 2153
NGU_PORT = 2152
TAC = 1
```

### 3.2 On `serber-minipc` (DU + USRP B210)

```bash
# 4. Verify Ethernet connectivity to CU
ping -c 3 10.76.170.38

# 5. Build and start DU
cd /home/serber/cu-du/source/openairinterface5g
# Apply SIB8/PWS patch if not already applied
git checkout 102965a669b9444857c27843ec8ce62780bf9d37
# [patch apply step]
cmake Build/oai_gnb -j$(nproc)
./targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf 2>&1 | tee /tmp/oai-du-ethernet.log
```

**DU config file**: `gnb-minipc.conf`  
**DU log file**: `/tmp/oai-du-ethernet.log` (configurable via `conf/local/lab.env`: `DU_LOG`)

Key DU config parameters (from `conf/templates/ethernet-du.yml`):

```
GNB_ID = 0xe00
GNB_DU_ID = 0xe01
GNB_NAME = gNB-CU-MINIPC
F1_LOCAL_IP_ADDRESS = live minipc Ethernet IP
F1_PEER_IP_ADDRESS = 10.76.170.38
F1_PORT = 2153
USRP_DEVICE_ARGS = master_clock_rate=30.72e6
DEVICE_TYPE = USRP B210
RF_BOARD = 0
CHANNEL = 1
BAND = 78
NUMBER_OF_UE = 1
TARGET_NB_OF_ROOT_SEQUENCE = 69
NRCellID = 0xE00
Tac = 1
MCC = 1
MNC = 1
```

---

## 4. Configuration Files Reference

| File | Host | Role |
|---|---|---|
| `/home/serber/cu-du-minipc-backhaul/source/oai-cn5g/docker-compose-minipc.yaml` | `serber-firecell` | 5G Core Network containers |
| `/home/serber/cu-du-minipc-backhaul/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc.conf` | `serber-firecell` | CU configuration |
| `/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf` | `serber-minipc` | DU source configuration + B210 radio |
| `/tmp/oai-tui-gnb-minipc-ethernet-runtime.conf` | `serber-minipc` | TUI runtime DU config with live Ethernet IP |
| `conf/local/lab.env` | Both | Paths, hostnames, SSH options, backhaul parameters |

---

## 5. Validation Checklist

After starting all components in order, perform the following checks:

### 5.1 F1 Connection

```
# On serber-minipc: check F1-C SCTP association
ss -tlnp | grep 2153

# On serber-firecell: check CU is listening for F1
ss -tlnp | grep 2153

# Check F1AP setup in CU log
grep -E "(F1AP|f1_setup|F1SetupRequest|F1SetupResponse)" /tmp/oai-cu-ethernet.log

# Check F1AP setup in DU log
grep -E "(F1AP|f1_setup|F1SetupRequest|F1SetupResponse)" /tmp/oai-du-ethernet.log
```

Expected: F1SetupRequest sent by DU, F1SetupResponse received, SCTP association established on port 2153.

Latest TUI evidence:

- Runtime DU config used `local_n_address = "10.76.170.109"` and
  `remote_n_address = "10.76.170.38"`.
- CU log showed `CU_handle_F1_SETUP_REQUEST` and F1 setup response.
- DU log showed `DU_handle_F1_SETUP_RESPONSE`, received F1 setup response,
  SIB8/PWS configuration, B210 detection, and radio sync.
- Packet capture showed SCTP F1-C heartbeats on minipc `enp4s0` and firecell
  `enp6s0`.
- Packet captures on minipc WiFi, Quectel `wwan0`, `wg-quectel-f1`, and
  firecell WiFi/WireGuard showed no F1 traffic.

### 5.2 SIB8/PWS Configuration

If PWS/SIB8 is enabled:

```
# Apply PWS message (on serber-firecell or via TUI)
./scripts/oai-lab-tui --apply-pws ethernet_cu_du_sib8 --message "Test warning message"

# Verify SIB8 scheduling in DU log
grep -E "(SIB8|sib8|PWS|write_replace_warning)" /tmp/oai-du-ethernet.log
```

### 5.3 UE Registration (Nothing Phone)

1. Ensure Nothing Phone has no existing registration (toggle airplane mode if needed).
2. Wait for cell search and selection on the Nothing Phone.
3. Check registration status on `serber-minipc`:

```
# Monitor UE attachment
grep -E "(RRCSetup|UE|attach|DL|DTCH|PDSCH)" /tmp/oai-du-ethernet.log | tail -20
```

4. Verify registration on Core side:

```bash
# On serber-firecell
docker exec <amf-container> showsupi
```

### 5.4 User-Plane Data

With UE registered, run a speed test from the Nothing Phone and record results.

---

## 6. Throughput Measurement Method

1. Register Nothing Phone on the access cell.
2. Run `wget` or `curl` to a known Internet endpoint from the phone, or use a speed test app.
3. Record downlink throughput observed on the phone.
4. Also monitor on the DU log:

```
# On serber-minipc
grep -E "(PDCP|throughput|MB/s|TB_SIZE)" /tmp/oai-du-ethernet.log | tail -20
```

**Baseline**: `19–23 Mb/s` observed with this setup.

---

## 7. Explicit Rollback Procedure

Use this procedure to restore Ethernet F1 if Quectel backhaul experiments fail.

### On `serber-minipc`:

```bash
# 1. Stop DU cleanly
# Find and kill the gnb process
pkill -f gnb-minipc.conf || true

# 2. Stop any Quectel/WireGuard overlay
# [WireGuard teardown]
ip link del wg-quectel-f1 2>/dev/null || true

# 3. Restore Ethernet routing for F1
# Remove any policy routing rules added for Quectel
ip rule del from 10.250.0.0/30 table 100 2>/dev/null || true

# 4. Verify management connectivity
ping -c 3 10.76.170.38
```

### On `serber-firecell`:

```bash
# 1. Stop CU cleanly
pkill -f gnb-cu-minipc.conf || true

# 2. Ensure Core Network is healthy
docker ps | grep -E "(amf|smf|nrf)" 
```

### Restart in Ethernet mode:

```bash
# On serber-firecell
cd /home/serber/cu-du-minipc-backhaul/source/oai-cn5g
docker-compose -f docker-compose-minipc.yaml up -d
sleep 15
./targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-minipc.conf 2>&1 | tee /tmp/oai-cu-ethernet.log &

# On serber-minipc (after CU is listening)
sleep 10
./targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf 2>&1 | tee /tmp/oai-du-ethernet.log &
```

### Rollback verification:

1. F1-C SCTP on port 2153 between `10.76.170.100` and `10.76.170.38`.
2. Nothing Phone registers.
3. SIB8/PWS works if enabled.
4. Throughput `~19–23 Mb/s`.

---

## 8. OAI Commit Pin Confirmation

Every component (CU, DU, SIB8/PWS patch) must build from OAI commit:

```
102965a669b9444857c27843ec8ce62780bf9d37
```

Verify:

```bash
# On both hosts
cd /path/to/openairinterface5g
git log --oneline -1
# Must output: 102965a669b9444857c27843ec8ce62780bf9d37
```

---

## 9. Limitations of This Document

This document describes the **known** procedure based on repository records, configuration templates, and audit evidence. It has not been executed at runtime during this Phase 1 documentation pass.

**Runtime verification required**: Before proceeding with Quectel experiments, manually confirm the rollback procedure works end-to-end on the actual hardware.

If runtime verification is blocked (e.g., hosts unreachable, hardware unavailable), proceed with documented evidence and clearly state what remains unverified.

---

## 10. Files Referenced

- `conf/templates/ethernet-cu.yml`
- `conf/templates/ethernet-du.yml`
- `conf/local/lab.env`
- `patches/sib8/oai-pws-sib8-cu-du.patch`
- `inventory/hosts.yml`
- `inventory/baselines.yml`
- `audit/SOURCE_REPOS.md`
