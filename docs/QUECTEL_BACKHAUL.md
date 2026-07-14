# Quectel F1 backhaul

## Target

The supported target is one 5GC and one shared CU on Firecell, one independent
donor DU serving only the Quectel modem, and one access DU whose F1 runs through
WireGuard over the Quectel data interface.

## Required proof

- donor-DU F1 association to the shared CU;
- Quectel registration on the donor cell and assigned data address;
- access-DU F1-C and F1-U on `wg-quectel-f1`;
- WireGuard outer UDP on the detected Quectel interface;
- no F1 leakage onto management Ethernet or Wi-Fi;
- access-cell PWS, registration, PDU, internet, and throughput on the phone;
- verified rollback to Ethernet.

## Current limitation

The maintained TUI still contains a legacy caged path that starts a monolithic
donor gNB. That path may help diagnose modem and overlay behavior, but it cannot
satisfy the target because the donor has no F1 association. It must not be
presented as a canonical Quectel PASS.

## Security

WireGuard private keys and subscriber values are generated or injected locally
and must never be copied into tracked configuration or evidence.
