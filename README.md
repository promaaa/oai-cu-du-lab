# OAI CU/DU Lab

Canonical control repository for an OpenAirInterface 5G NR CU/DU split lab
with SIB8/PWS and Ethernet, Wi-Fi GRE, and Quectel/WireGuard F1 transports.

This repository is the operator and reproducibility layer. It runs on a Mac
and controls the Linux lab hosts over SSH. OAI source, 5GC data, generated
configs, radio drivers, subscriber credentials, WireGuard keys, raw logs, and
packet captures remain outside Git.

## Professor quick start

Use this path when the lab hosts are already deployed and the private
environment file has been provided.

### 1. Clone and enter the repository

```bash
git clone https://github.com/promaaa/oai-cu-du-lab.git
cd oai-cu-du-lab
```

### 2. Install the only local dependency

The Mac needs Node.js 18 or newer and its built-in OpenSSH client.

```bash
node --version
ssh -V
```

If Node.js is missing and Homebrew is installed:

```bash
brew install node
```

Docker, OAI, UHD, QMI, WireGuard, and Linux networking tools are required on
the remote lab hosts, not on the Mac.

### 3. Add the private environment file

Preferred:

```bash
mkdir -p conf/local
cp /path/to/private-lab.env conf/local/lab.env
chmod 600 conf/local/lab.env
```

The file may instead stay outside the clone:

```bash
./oai-lab --env="$HOME/private/oai-lab.env" --doctor
```

The TUI also recognizes a root `.env` or the `OAI_LAB_ENV` variable. Shell
variables override file values. Live actions fail closed if no private
environment file is loaded.

For configuration switching, the file should define at least:

```text
CU_HOST
DU_HOST
DU_LABEL
MINIPC_HOST
PI_HOST
JETSON_HOST
CU_CN_DIR
CU_OAI_DIR
DU_OAI_DIR
```

See [conf/lab.env.example](conf/lab.env.example) for every supported setting.
Never commit the private file.

### 4. Check the Mac without contacting the lab

```bash
./oai-lab --doctor
node scripts/tests/oai-lab-tui-static.test.mjs
```

`--doctor` checks Node.js, OpenSSH, environment loading, file permissions, and
the private evidence directory. The static suite does not contact any host.

### 5. Obtain exclusive lab ownership

Before any launch:

1. Read [current status](docs/STATUS.md) and
   [baselines](docs/BASELINES.md).
2. Confirm nobody else is operating the core, CU, DUs, radios, modem, routes,
   tunnels, or test phone.
3. Locate B210 serial `8002816` physically and confirm which DU owns it.
4. Keep the MiniPC Ethernet CU/DU deployment available as the rollback path.

Do not infer radio ownership or scenario health from an old process, USB
listing, directory name, or previous result.

### 6. Verify remote access before changing anything

Start with the canonical rollback configuration:

```bash
./oai-lab --du=serber-minipc --backhaul=ethernet --verify
```

`--verify` contacts the configured CU and DU but does not launch the scenario.
If it fails, check VPN/network access, SSH keys or agent state, host values in
the env file, and the remote directory paths before proceeding.

### 7. Launch the interactive console

```bash
./oai-lab
```

The console lets the operator:

- select MiniPC, Raspberry Pi, or Jetson as the access DU;
- select Ethernet, Wi-Fi GRE, or Quectel/WireGuard F1;
- launch the selected split configuration;
- launch the monolithic reference;
- update PWS/SIB8 warning text;
- inspect host, process, core, and log state;
- stop the current configuration and clean scenario-owned residue.

Start with `serber-minipc` and `Ethernet F1`. Treat every other scenario as an
experiment until its current status and prerequisites have been checked.

## Direct deployment commands

The interactive console is recommended. The equivalent CLI commands are:

| Access DU | Ethernet F1 | Wi-Fi GRE F1 | Quectel/WireGuard F1 |
|---|---|---|---|
| MiniPC | `./oai-lab --minipc-ethernet --start-ethernet` | `./oai-lab --minipc-wifi-gre --start-wifi-gre` | `./oai-lab --minipc-quectel-wg --start-quectel-wg` |
| Raspberry Pi | `./oai-lab --pi-ethernet --start-ethernet` | `./oai-lab --pi-wifi-gre --start-wifi-gre` | `./oai-lab --pi-quectel-wg --start-quectel-wg` |
| Jetson | `./oai-lab --jetson-ethernet --start-ethernet` | `./oai-lab --jetson-wifi-gre --start-wifi-gre` | `./oai-lab --jetson-quectel-wg --start-quectel-wg` |

Verify a selection before launching it:

```bash
./oai-lab --du=serber-jetson --backhaul=quectel-wg --verify
```

Other available workflows:

```bash
# Monolithic firecell reference
./oai-lab --start-mono

# Legacy caged Quectel workflow; not proof of the target one-CU/two-DU design
./oai-lab --start-caged-quectel
./oai-lab --validate-caged-quectel

# Stop the caged workflow and restore cleanup/rollback handling
./oai-lab --rollback-caged-quectel

# Read-only inspection
./oai-lab --status
./oai-lab --logs
```

Menu or command availability does not mean that a scenario currently passes.
The authoritative classifications are in [docs/STATUS.md](docs/STATUS.md).

## Standard redeployment sequence

Use this order for each configuration:

1. Run `./oai-lab --doctor`.
2. Obtain exclusive ownership and confirm physical radio placement.
3. Run the selected configuration with `--verify`.
4. Launch it through the interactive console or the matching start command.
5. Wait for core, F1-C/F1-U, RF synchronization, and timing gates.
6. On the test phone, confirm APN/DNN `oai`, toggle airplane mode once, and
   record PWS reception, registration, PDU session, internet, and throughput.
7. Inspect `./oai-lab --status` and `./oai-lab --logs`.
8. Stop the scenario from `Stop the current config` in the TUI.
9. Check for remaining processes, routes, tunnels, firewall rules, MTU changes,
   and radio ownership.
10. Restore and verify the MiniPC Ethernet rollback before moving to another
    transport.

A machine-side launch is not a full PASS. Full acceptance requires fresh,
separate evidence for phone-visible PWS, registration, PDU session, internet,
and timestamped downlink and uplink throughput.

## Rollback

The canonical rollback is MiniPC Ethernet CU/DU with SIB8.

From the interactive console:

1. Select `Stop the current config`.
2. Select MiniPC as the DU.
3. Select Ethernet F1.
4. Launch the selected CU/DU configuration.
5. Recheck machine gates and then phone gates.

For the caged Quectel workflow:

```bash
./oai-lab --rollback-caged-quectel
./oai-lab --minipc-ethernet --start-ethernet
```

If cleanup is incomplete, follow
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) and remove only
scenario-owned state. Preserve management access and existing evidence.

## Rebuilding a remote OAI deployment

The Mac clone alone cannot create a bare Linux radio host. A remote rebuild
requires the host packages, UHD/radio access, OAI 5GC or RAN dependencies,
private subscriber data, generated configs, and any WireGuard keys appropriate
to that machine.

For each remote OAI tree:

1. Clone OpenAirInterface outside this repository.
2. Check out the pinned split baseline commit:

   ```bash
   git checkout 102965a669b9444857c27843ec8ce62780bf9d37
   ```

3. Apply only the required feature-separated patches from
   [patches/](patches/), following each patch directory's README.
4. Build OAI on the target Linux host using the host's established OAI build
   workflow.
5. Place generated runtime configs outside Git and update the private env file
   with their absolute remote paths.
6. Restore credentials and keys from the approved private source; never copy
   them into this repository.
7. Run `./oai-lab --doctor`, then `--verify`, then restore the Ethernet
   rollback before attempting Wi-Fi GRE or Quectel/WireGuard.
8. Record the actual OAI commit and local patch state in sanitized run evidence.

The repository intentionally does not automate secret provisioning or pretend
that an unverified fresh host is equivalent to the rollback baseline.

## Evidence and security

Private run evidence is stored outside the repository:

```text
~/.local/state/oai-cu-du-lab/runs/<timestamp>_<scenario>/
```

Override it with:

```bash
export OAI_LAB_STATE_DIR=/private/path
```

Never commit UE `Ki` or `OPc`, passwords, tokens, private keys, subscriber
dumps, private env files, generated configs, raw logs, packet captures,
databases, or core dumps. Only minimized and reviewed conclusions belong in
the canonical status documentation.

## Repository map

- `conf/` — sanitized templates; ignored local/generated configuration.
- `docs/` — architecture, status, operation, troubleshooting, and security.
- `patches/` — feature-separated changes for the pinned external OAI source.
- `scripts/` — the TUI, focused helpers, and static tests.
- `wiki/` — the concise browser-readable operator reference.

## Read next

- [Current status](docs/STATUS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Baselines](docs/BASELINES.md)
- [Network and hardware](docs/NETWORK.md)
- [Operator guide](docs/OPERATOR_GUIDE.md)
- [Quectel backhaul](docs/QUECTEL_BACKHAUL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Security](docs/SECURITY.md)
