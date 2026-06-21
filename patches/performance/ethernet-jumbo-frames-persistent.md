# Persistent Jumbo Frames for F1 Ethernet Backhaul

The `oai-lab-tui` startup sequence applies MTU 9000 transiently at runtime (`ip link set <iface>
mtu 9000`) and reverts to 1500 on stop. This survives as long as neither node reboots.

To make jumbo frames **persistent across reboots**, deploy the following systemd-networkd override
on each node. Confirm interface names with `ip -br link show` before deploying.

---

## serber-minipc (DU) — F1 interface: `enp4s0`

```
# /etc/systemd/network/10-enp4s0-jumbo.network
[Match]
Name=enp4s0

[Link]
MTUBytes=9000
```

## serber-firecell (CU/CN) — F1 interface: typically `enp6s0` (verify at runtime)

```
# /etc/systemd/network/10-enp6s0-jumbo.network
[Match]
Name=enp6s0

[Link]
MTUBytes=9000
```

Apply on each host (requires systemd-networkd to be managing that interface):

```bash
sudo mkdir -p /etc/systemd/network
sudo tee /etc/systemd/network/10-enp4s0-jumbo.network << 'UNIT'
[Match]
Name=enp4s0

[Link]
MTUBytes=9000
UNIT
sudo systemctl restart systemd-networkd
ip link show enp4s0 | grep mtu   # should say mtu 9000
```

---

## Prerequisites

- The physical switch (or direct cable) between the two nodes must support frames ≥ 9000 B.
  Verify with: `ping -s 8972 -M do -c 3 <peer_ip>` (8972 B data + 28 B IP/ICMP = 9000 B frame).
- If a managed switch is in the path, enable jumbo frames on the relevant ports before testing.

---

## Verification

```bash
# After applying, confirm MTU:
ip link show enp4s0 | grep mtu          # expect: mtu 9000

# Send a large ICMP probe to confirm the path supports jumbo frames end-to-end:
ping -s 8972 -M do -c 5 10.76.170.38   # from serber-minipc to serber-firecell

# Confirm GTP-U frames are no longer fragmented during a live split run:
# (Check ip -s link show enp4s0: 'missed' counter should not grow during iperf3 DL traffic)
```
