# System

## Functional Objective

The lab studies an OAI 5G NR CU/DU split that supports SIB8/PWS broadcast and can carry F1 over controlled IP transports, including Ethernet, Wi-Fi GRE, and the Quectel 5G backhaul target.

## Core Split Architecture

`serber-firecell` hosts the OAI 5GC and CU. `serber-minipc` hosts the access DU and USRP B210 serial `8002816`. The CU owns RRC-level behavior. The access DU handles MAC/RLC/PHY scheduling and radio transmission for the caged Nothing Phone.

## Quectel Backhaul Architecture

Quectel backhaul always refers to this specific setup:

- `serber-firecell`: one OAI 5GC and one shared OAI CU.
- donor DU: connects to the shared CU and provides the independent donor cell used only by the Quectel modem.
- Quectel RM500Q-GL: outside the cage, attached only to the donor-DU cell.
- `serber-minipc`: access DU with B210 serial `8002816`, PCI `0`, TAC `1`, DU ID `0xe01`.
- minipc F1: `10.250.0.2` to CU `10.250.0.1` on `wg-quectel-f1`, with WireGuard outer UDP over `wwan0`.

The single-host reference remains a separate benchmark and is not part of this
backhaul architecture. Older launchers and reports describing a combined donor
must be treated as historical until they are migrated and revalidated against
the one-CU/two-DU target.

## SIB8/PWS Role

SIB8 carries public warning messages to UEs. In the split deployment, the CU constructs or triggers warning content, forwards it over F1AP, and the DU schedules the resulting system information over the access cell.

## Future Portable DU Direction

The longer-term direction is a portable or drone-carried DU with local access radio and a wireless backhaul to a ground CU/Core.
