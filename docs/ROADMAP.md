# Roadmap

## Current Next Objective

Establish F1 backhaul through the Quectel module connected to `serber-minipc`, while continuing to use the USRP B210 on `serber-minipc` for local 5G radio access.

The same-cell Quectel path is not a stable full-F1 solution because it creates a circular dependency. Future work should prefer an independent Quectel donor path or equivalent independent cellular/IP backhaul.

## Later Objectives

- Compare Ethernet, Wi-Fi GRE, and Quectel/WireGuard performance.
- Migrate and validate a Raspberry Pi 5 DU, including the planned 16 GB hardware migration.
- Develop a drone-carried DU architecture with a wireless backhaul.

Implementation has not started in this canonical repository.
