# Roadmap

## Current Objective

Establish the Quectel 5G F1 backhaul using the lab's single-CU split architecture:

- `serber-firecell`: one OAI 5GC, one OAI CU, and the firecell donor DU.
- `serber-minipc`: minipc access DU with USRP B210 serial `8002816`.
- Quectel RM500Q-GL: outside the cage, attached only to the firecell donor DU.
- F1 from minipc access DU to CU: `wg-quectel-f1` over the Quectel PDU session.
- F1 from firecell donor DU to CU: local firecell path only.

The old oai-pc/monolithic donor path is removed from the Quectel backhaul plan.
The monolithic deployment remains a separate reference baseline, not a donor for
Quectel F1.

## Work In Progress

- Security and repository audit: complete.
- Ethernet rollback baseline: complete.
- Quectel modem and network inventory: complete, refresh live values per run.
- Firecell donor DU local-F1 config and start flow: implemented.
- Shared CU plus minipc access DU WireGuard-F1 configs: implemented.
- Packet-gated validation: implemented; runtime PASS still requires live
  tcpdump evidence and caged phone traffic.

## Later Objectives

- Compare Ethernet, Wi-Fi GRE, and Quectel/WireGuard performance.
- Migrate and validate lightweight DU hardware only after the Quectel path is stable.
- Develop a portable or drone-carried DU architecture with local access radio and wireless backhaul.
