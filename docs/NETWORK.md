# Network

## Hosts

| Host | Role | Notes |
|---|---|---|
| `serber-firecell` | Core Network and CU | Current split baseline uses management IP `10.76.170.38`; OAI CN subnet includes `192.168.71.129/132` evidence. |
| `serber-minipc` | DU, USRP B210 access, Quectel backhaul experiments | Current verified management target is `serber@10.76.170.40` on `enp2s0`; aliases and older addresses have drifted. Wi-Fi GRE evidence includes `wlp3s0` at `10.85.168.144`; Quectel evidence includes `wwan0` and `wg-quectel-f1`. |
| `serber-pi` | Experimental lightweight DU | Current verified management target is `serber@10.76.170.18` on `eth0`; OAI source is pinned at the split baseline commit. |
| `oai-pc` | Powerful validation PC | Used to rule out hardware limits and for phone-screen validation. Older docs also call an OAI PC `oai`. |

## Hardware Relationships

- USRP B210 remains the local 5G access radio for `serber-minipc`.
- Quectel RM500Q-GL on `serber-minipc` is the intended F1/backhaul modem.
- Nothing Phone is the commercial UE used for validation.

## Backhaul Variants

- Ethernet F1: canonical rollback baseline.
- Wi-Fi GRE F1: verified wireless-backhaul baseline.
- Quectel/WireGuard F1: partial packet-path evidence; stable full F1 is not yet validated.
- Quectel donor DU: independent cell attached to the shared CU; required so the modem does not depend on the access cell it is backhauling.

## Identifier Policy

Allowed here when useful: hostnames, usernames already present in source repos, infrastructure IP addresses, interface names, and non-secret topology IDs.

Never commit: UE `Ki`, `OPc`, passwords, tokens, private keys, raw subscriber dumps, unsanitized logs, or packet captures.
