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

## Docker Core Bridge

The split-core Docker network must be recreated after adding an MTU driver option. In the
external deployment Compose file, keep the existing bridge name and add:

```yaml
networks:
  public_net:
    driver: bridge
    name: oai-cn5g-minipc-public-net
    driver_opts:
      com.docker.network.bridge.name: "oai-cn5g-minipc"
      com.docker.network.driver.mtu: "9000"
```

Validate before recreation, then use the deployment's normal core restart procedure:

```bash
docker compose -f docker-compose-minipc.yaml config -q
docker compose -f docker-compose-minipc.yaml down
docker compose -f docker-compose-minipc.yaml up -d
```

Confirm both the host bridge and the UPF veth report MTU 9000. Recreating only the core can
leave an already-running CU without a usable UE session; restart the Ethernet CU/DU stack if
the UE does not reattach.

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

# Confirm whether GTP-U frames are fragmented during a live split run. Do not infer this from
# aggregate IP fragment counters alone: UE-originated inner packets can also be fragmented.
sudo tcpdump -ni oai-cn5g-minipc \
  'src host <upf-ip> and (ip[6:2] & 0x3fff != 0)'
```

The 2026-06-22 live diagnostic verified that the Docker bridge and UPF veth reached MTU 9000
and found no repeatable UPF-originated downlink fragments during large UE pings. It still saw
UE-originated inner fragments. A synchronized phone throughput run is therefore required
before claiming that this change raises the 19-23 Mb/s Ethernet baseline.
