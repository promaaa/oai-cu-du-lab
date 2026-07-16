# Operator guide

## Before touching the lab

Read `STATUS.md`, obtain sole ownership of the shared lab, and discover the
physical B210 location. Do not infer ownership from old configuration.

## Start the TUI

On a fresh Mac clone:

```bash
cp /path/to/private-lab.env conf/local/lab.env
chmod 600 conf/local/lab.env
./oai-lab --doctor
./oai-lab
```

Node.js 18 or newer and the macOS OpenSSH client are the only local runtime
requirements. If Node.js is missing and Homebrew is installed, run
`brew install node`. The radio, core, Docker, Linux networking, and modem tools
remain on the remote lab hosts; they are not installed on the professor's Mac.

The environment file can instead remain anywhere outside the clone:

```bash
./oai-lab --env="$HOME/private/oai-lab.env" --doctor
./oai-lab --env="$HOME/private/oai-lab.env"
```

Shell-exported variables take precedence over values in the file. The TUI
accepts both `KEY=value` and `export KEY=value` lines and does not print secret
values during local checks. Live actions fail closed when no private environment
file is loaded. Set `MINIPC_HOST`, `PI_HOST`, and `JETSON_HOST` to avoid using
the documented fallback addresses when switching among all DU configurations.

Useful local checks:

```bash
./oai-lab --help
./oai-lab --doctor
node scripts/tests/oai-lab-tui-static.test.mjs
```

`--verify` contacts configured hosts; the static test does not.

## Trying each configuration

The interactive `Change selected DU/config` screen exposes the full 3×3
matrix: MiniPC, Raspberry Pi, or Jetson with Ethernet, Wi-Fi GRE, or
Quectel/WireGuard F1. CLI selection is also clone-independent:

```bash
./oai-lab --du=serber-minipc --backhaul=ethernet --verify
./oai-lab --du=serber-pi --backhaul=wifi-gre --verify
./oai-lab --du=serber-jetson --backhaul=quectel-wg --verify
```

After read-only verification, replace `--verify` with the matching
`--start-ethernet`, `--start-wifi-gre`, or `--start-quectel-wg` only while the
professor has exclusive lab ownership. Menu availability is not evidence that
a historical or blocked scenario has passed; retain the classifications in
`STATUS.md` and `BASELINES.md`.

## Runtime evidence

Run records are private local state, not repository content:

```text
~/.local/state/oai-cu-du-lab/runs/<timestamp>_<scenario>/
```

Set `OAI_LAB_STATE_DIR=/private/path` to use another location. Review and
sanitize evidence before copying a minimal conclusion into `STATUS.md` or
`BASELINES.md`. Never commit raw logs or captures.

## Standard validation order

1. Record repository and external OAI commits.
2. Record host, radio, transport, and active process ownership.
3. Confirm the Ethernet rollback can be restored.
4. Start core, CU, DU, radio, and selected transport through the TUI.
5. Verify machine gates without labeling them a scenario PASS.
6. Record phone PWS, registration, PDU, internet, and throughput separately.
7. Stop through the TUI and check process, route, firewall, MTU, and tunnel
   residue.
8. Update canonical status with only sanitized conclusions.

## Focused collection

```bash
./scripts/collect-split-performance-window.sh 60
./scripts/collect-software-power-profile.sh 60
```

Power telemetry is planning evidence only until the complete payload is
measured at its DC input.
