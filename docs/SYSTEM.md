# System

## Functional Objective

The lab studies an OAI 5G NR CU/DU split that supports SIB8/PWS broadcast and can later use a wireless F1 backhaul for a lightweight or drone-carried DU.

## Architecture

`serber-firecell` hosts the 5G Core and CU. `serber-minipc` hosts the DU and the USRP B210 access radio. F1-C and F1-U connect CU and DU over IP transport.

The CU owns RRC-level behavior. The DU handles MAC/RLC/PHY scheduling and radio transmission through the USRP B210.

## SIB8/PWS Role

SIB8 carries public warning messages to UEs. In the split deployment, the CU constructs or triggers warning content, forwards it over F1AP, and the DU schedules the resulting system information over the access cell.

## F1 Backhaul Role

F1 is the transport path between CU and DU. The verified rollback path is Ethernet. Wi-Fi GRE is a verified wireless experiment. The next target is Quectel modem based IP backhaul, likely through a WireGuard overlay.

## Monolithic Versus Split

The monolithic OAI deployment is retained as a reference-only baseline. Active work targets split deployments where CU/Core and DU/radio can be placed on separate hosts.

## Future Portable DU Direction

The longer-term direction is a portable or drone-carried DU with local access radio and a wireless backhaul to a ground CU/Core.
