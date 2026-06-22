# Roadmap

## Current Objective

Establish the Quectel 5G F1 backhaul using the lab's single-CU split architecture:

- `serber-firecell`: one OAI 5GC and one shared OAI CU.
- donor radio path: one donor DU attached to the shared CU and serving only the Quectel modem.
- `serber-minipc`: minipc access DU with USRP B210 serial `8002816`.
- Quectel RM500Q-GL: outside the cage, attached only to the donor-DU cell.
- F1 from minipc access DU to CU: `wg-quectel-f1` over the Quectel PDU session.
- F1 from donor DU to CU: independent of the Quectel-carried access-DU F1 path.

Older combined-donor launch paths remain historical and are not evidence for
the target. The new topology must fail closed until both DUs are proven against
the same CU without creating a circular dependency.

## Work In Progress

- Security and repository audit: complete.
- Ethernet rollback baseline: complete.
- Quectel modem and network inventory: complete, refresh live values per run.
- One-CU/two-DU launch flow: not yet validated; older TUI actions are legacy.
- CU plus minipc access-DU WireGuard-F1 configs: available but require migration validation with the donor DU.
- Packet-gated validation: must be extended to prove both F1 associations;
  runtime PASS still requires live sanitized captures and caged phone traffic.

## Later Objectives

- Compare Ethernet, Wi-Fi GRE, and Quectel/WireGuard performance.
- Migrate and validate lightweight DU hardware only after the Quectel path is stable.
- Develop a portable or drone-carried DU architecture with local access radio and wireless backhaul.
