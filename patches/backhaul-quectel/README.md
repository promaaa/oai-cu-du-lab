# Quectel Backhaul

No old Quectel scripts are migrated yet.

Reason: the source scripts include live-machine assumptions, SSH/password flows, generated-config behavior, and private-key handling that should be rewritten before becoming canonical.

Essential retained facts are in:
- `docs/ROADMAP.md`
- `docs/NETWORK.md`
- `conf/templates/quectel-wireguard.yml`
- `inventory/radios.yml`

Future scripts should be limited to:
- modem detection;
- independent donor connectivity check;
- WireGuard config rendering with local-only private keys;
- F1 path validation that proves no Ethernet/Wi-Fi fallback;
- rollback to Ethernet CU/DU with SIB8.
