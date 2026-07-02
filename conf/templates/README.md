# Config Templates

These are sanitized source templates for future generated OAI configs. They are not ready-to-run configs.

Rules:
- Keep host addresses and radio parameters here only when they are useful topology facts.
- Keep UE credentials, subscriber database rows, passwords, keys, generated OAI `.conf` files, logs, and captures out of Git.
- Write rendered configs to `conf/generated/` or directly into an external OAI tree; `conf/generated/` is ignored except for `.gitkeep`.

Template set:
- `ethernet-cu.yml`: canonical CU side for Ethernet rollback.
- `ethernet-du.yml`: canonical DU/access-radio side for Ethernet rollback.
- `jetson-du.yml`: Jetson Orin Nano DU/access-radio side, matching the Ethernet DU baseline except for host-specific runtime details.
- `wifi-gre-overlay.yml`: Wi-Fi GRE transport parameters.
- `quectel-wireguard.yml`: Quectel/WireGuard target parameters and guardrails.
- `sib8.conf.template`: non-secret PWS/SIB8 warning-message template.
