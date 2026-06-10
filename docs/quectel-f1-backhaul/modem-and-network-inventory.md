# Modem and Network Inventory

**Phase**: 2  
**Date**: 2026-06-01  
**Branch**: `main`  
**Status**: Inventory — to be executed on `serber-minipc` and `serber-firecell`

---

## 1. Inventory Objective

Determine the current state of the Quectel RM500Q-GL modem on `serber-minipc` and the network paths available to `serber-firecell`, before configuring any F1 backhaul overlay.

The primary goal is to verify that the Quectel modem can reach `serber-firecell`
through the firecell monolithic donor gNB, not through the OAI access cell emitted by the
B210 on `serber-minipc`.

---

## 2. Execution Instructions

All commands below are to be executed on `serber-minipc` unless otherwise noted.

### 2.1 Modem Detection

```bash
# List USB devices — look for Quectel modem
lsusb | grep -i quectel

# Check USB serial devices
ls -la /dev/ttyUSB* /dev/cdc-wdm* 2>/dev/null

# Check if ModemManager is running
systemctl status ModemManager 2>/dev/null || ps aux | grep -i modemmanager

# Check kernel module for QMI/MBIM
lsmod | grep -i qmi
```

Expected hardware: Quectel RM500Q-GL, USB ID typically `2c7c:0800` (5G mode) or similar.

### 2.2 ModemManager Inspection

```bash
# List modem interfaces
mmcli -L 2>/dev/null || echo "ModemManager not available or no modems detected"

# If modems found, get details
mmcli -m <modem-index> 2>/dev/null

# Specifically look for RM500Q
mmcli -m any --simple-status 2>/dev/null
```

Key questions to answer:

- Is the modem detected by ModemManager?
- Is the SIM inserted and recognized?
- Is the modem registered on a network?
- What is the signal quality (CSQ/RSRP)?
- Is a data session active?

### 2.3 QMI/MBIM Data Session

```bash
# Check for QMI wwan interface
ip link show wwan0 2>/dev/null
ip addr show wwan0 2>/dev/null

# Check QMI data connection status
# Using qmicli (if available)
qmicli -d /dev/cdc-wdm0 --dms-get-operating-mode 2>/dev/null || echo "qmicli not available"

# Check network registration
qmicli -d /dev/cdc-wdm0 --nas-get-network-selection-mode 2>/dev/null || echo "qmicli not available"

# Check signal strength
qmicli -d /dev/cdc-wdm0 --nas-get-signal-info 2>/dev/null || echo "qmicli not available"
```

### 2.4 Modem Firmware Information

```bash
# Get firmware version (if accessible safely)
mmcli -m <modem-index> --command "AT+QGMR" 2>/dev/null || echo "Firmware version not accessible via ModemManager"
```

Record firmware version for bug tracking.

### 2.5 Network Interface State

```bash
# List all network interfaces
ip link show
ip addr

# Show routes
ip route
ip route show table all

# Check DNS settings
cat /etc/resolv.conf
```

Identify:

- `wwan0` interface and its IP address (if any)
- Routes via `wwan0`
- Default route status (must NOT be displaced by Quectel without policy routing)
- DNS configuration

### 2.6 Connectivity Test — Can Quectel Path Reach serber-firecell?

```bash
# Ping the CU management IP through wwan0 if IP is assigned
# (This only works if wwan0 has an IP and routing is set)
ping -I wwan0 -c 3 10.76.170.38 2>/dev/null || echo "Cannot ping CU through wwan0 directly"

# Alternative: check if there's a route to 10.76.170.38 via wwan0
ip route get 10.76.170.38

# Check routing table for wwan0 specific routes
ip route | grep wwan
```

---

## 3. serber-firecell Side Inventory

Execute on `serber-firecell`:

```bash
# List interfaces
ip link show
ip addr

# Show routes
ip route

# Check firewall state (iptables/nftables)
iptables -L -n 2>/dev/null || echo "No iptables or permission denied"
nft list ruleset 2>/dev/null || echo "No nftables or permission denied"

# Check if serber-firecell is reachable from serber-minipc management interface
ping -c 3 10.76.170.38 2>/dev/null

# Check if WireGuard port 51821 is open
ss -tlnp | grep 51821 || echo "WireGuard not listening on serber-firecell yet"
```

---

## 4. Tunnel Endpoint Candidates

Based on `conf/templates/quectel-wireguard.yml`, the expected WireGuard endpoints are:

| Endpoint | Address | Port |
|---|---|---|
| CU side | `10.250.0.1` | `51821` |
| DU side | `10.250.0.2` | `51821` |
| WireGuard interface | `wg-quectel-f1` | — |

**Critical question**: Does `serber-firecell` need a public IP or port-forwarding for the WireGuard server to be reachable from `serber-minipc` over the Quectel cellular path?

If the Quectel modem connects to a carrier-grade NAT (CG-NAT) cellular network, then `serber-firecell` must either:

- be reachable via public internet (WireGuard server on public IP), or
- use a relay/proxy (e.g., tailscale, Cloudflare Tunnel, or a third-party relay).

---

## 5. Independent Donor Assessment

### Decision Gate 1

Answer the following before proceeding:

1. **Which network does the Quectel modem attach to?**
   - Is it the firecell donor gNB cell, PCI `1`, TAC `2`?
   - Is it the local OAI access cell emitted by `serber-minipc`?
   - Is it some other private network?

2. **Is it separate from the minipc access cell?**
   - If the modem attaches to the OAI cell emitted by the B210 on `serber-minipc`, this creates a circular dependency.
   - The DU needs F1 to function. F1 requires the Quectel path. The Quectel path requires the access cell. The access cell requires F1. **BLOCKED.**

3. **Does `serber-minipc` obtain working IP connectivity through the modem?**
   - Is `wwan0` assigned an IP?
   - Can `serber-minipc` reach the internet or `serber-firecell` through `wwan0`?

4. **Can `serber-minipc` reach `serber-firecell` through this path?**
   - Direct routing or WireGuard tunnel? Both must be verified.

5. **Is direct routing sufficient, or is an overlay tunnel required?**
   - If the Quectel modem gets a private/CG-NAT IP with no port forwarding, direct routing fails. WireGuard is required as the overlay.

---

## 6. Documentation Template for Inventory Results

Fill this in during actual inventory execution:

### Modem Hardware

| Property | Value |
|---|---|
| USB ID | `<detected>` |
| `/dev/cdc-wdm*` devices | `<detected>` |
| ModemManager status | `<detected/not detected>` |
| SIM status | `<ready/not detected>` |
| Network registration | `<registered/not registered>` |
| Signal quality (CSQ) | `<value>` |
| Firmware version | `<value>` |

### Network Interface

| Property | Value |
|---|---|
| `wwan0` exists | `<yes/no>` |
| `wwan0` IP address | `<value or none>` |
| Default route via `wwan0` | `<yes/no>` |
| DNS via `wwan0` | `<yes/no>` |

### Connectivity

| Test | Result |
|---|---|
| Ping `10.76.170.38` via `wwan0` | `<success/fail>` |
| Route to `10.76.170.38` | `<via wwan0/eth0/wlan0>` |
| Reachability to `serber-firecell` | `<confirmed/blocked/unknown>` |

### Donor Assessment

| Question | Answer |
|---|---|
| Network attached to | `<carrier/private-oai/other>` |
| Independent of access cell | `<yes/no/uncertain>` |
| Direct routing to CU possible | `<yes/no>` |
| Tunnel required | `<yes/no>` |

---

## 7. Outcomes

Based on this inventory, one of the following will be determined:

| Outcome | Condition | Action |
|---|---|---|
| **Proceed with Quectel F1** | Independent donor confirmed, IP connectivity exists, route to CU established | Continue to Phase 3 |
| **Firecell donor gNB blocked** | Modem only attaches to minipc access cell | Stop full F1 migration. Fix donor gNB registration. |
| **Modem not functional** | Modem not detected, no data session | Investigate modem hardware, SIM, driver. |
| **CG-NAT / no direct reachability** | Modem has private IP, CU not directly reachable | Consider relay/tailscale approach or document as blocking. |

---

## 8. Files Referenced

- `conf/templates/quectel-wireguard.yml`
- `conf/local/lab.env`
- `inventory/hosts.yml`
- `inventory/radios.yml`
- `docs/NETWORK.md`
- `docs/ROADMAP.md`
