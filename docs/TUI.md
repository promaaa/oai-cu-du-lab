# Operator TUI

Run from the repository root:

```bash
./scripts/oai-lab-tui
```

The TUI is the simple launch surface for the deployed lab. It is meant for a newcomer who knows the lab objective but does not want to remember every host path and command.

## First Setup

Create the ignored local profile:

```bash
./scripts/oai-lab-tui --init-local-config
```

Edit `conf/local/lab.env` for the actual machine names, OAI paths, config files, SSH options, and sudo behavior. By default the launcher uses:

- key-based SSH or an existing SSH agent;
- `sudo -n`, so commands fail cleanly instead of waiting for a password prompt;
- no stored passwords or subscriber secrets.

## Launch Modes

- `Start monolithic Core + gNB`: checks the monolithic host, detects/resets the USRP, starts the core, then starts `nr-softmodem`.
- `Start Ethernet CU/DU + SIB8`: checks both hosts, detects/resets the DU USRP, starts the core and CU on the CU host, then starts the DU on the DU host.
- `Start Wi-Fi GRE overlay`: creates the verified GRE tunnel and policy routes. After that, launch the Ethernet CU/DU mode.
- `Quectel preflight`: inspects the DU modem interface and WireGuard state.
- `Start Quectel/WireGuard F1`: starts the Quectel/WireGuard F1 path only when `QUECTEL_INDEPENDENT_DONOR=1`.

The Quectel full-start action is intentionally gated because the same-cell donor path is circular. Enable it only when the modem reaches the CU through an independent donor network.

Useful commands:

```bash
./scripts/oai-lab-tui --init-local-config
./scripts/oai-lab-tui --self-test
./scripts/oai-lab-tui --dashboard
./scripts/oai-lab-tui --dry-run --action status
./scripts/oai-lab-tui --dry-run --action start-monolithic
./scripts/oai-lab-tui --dry-run --action start-ethernet
./scripts/oai-lab-tui --action quectel-preflight
./scripts/oai-lab-tui --make-experiment quectel-independent-donor
```

Use `--dry-run` before a live launch to see the exact SSH/local commands that will run.
