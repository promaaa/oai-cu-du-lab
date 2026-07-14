# Network and hardware

These are management defaults, not a substitute for live discovery.

| Host | Default management target | Role |
|---|---|---|
| `serber-firecell` | `serber@10.76.170.38` | 5GC, shared CU, monolithic reference radio |
| `serber-minipc` | `serber@10.76.170.40` | canonical access DU, B210, Quectel experiments |
| `serber-pi` | `serber@10.76.170.18` | lightweight DU candidate |
| `serber-jetson` | `serber@10.76.170.8` | Jetson Orin Nano DU candidate |
| `oai-pc` | discover before use | X310 and high-performance validation host |

## Radios

- B210 serial `8002816`: movable access radio used by MiniPC, Pi, or Jetson;
  one host may own it at a time.
- Firecell B210 serial `35F8ABA`: monolithic reference radio.
- Quectel RM500Q-GL: intended independent wireless backhaul modem.
- USRP X310: transport-sensitive validation radio; 106 PRB is blocked on a
  negotiated 1 Gb/s path.

## Transport reference

| Transport | Interface or overlay | Requirement |
|---|---|---|
| Ethernet F1 | selected host Ethernet | verify route, MTU, link rate, and F1 isolation |
| Wi-Fi GRE F1 | `test-gre` | verify underlay reachability before CU/DU launch |
| Quectel F1 | `wg-quectel-f1` over `wwan0` | prove modem registration, WireGuard outer traffic, and F1-C/F1-U |

The canonical Quectel overlay uses CU `10.250.0.1` and access DU `10.250.0.2`.
Management traffic must remain outside the experimental backhaul path.

Never store UE authentication values, passwords, private keys, or subscriber
dumps in this file or any other tracked file.
