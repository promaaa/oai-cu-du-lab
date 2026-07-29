# OAI CU/DU Lab

Control repository for an OpenAirInterface 5G NR CU/DU split lab with SIB8/PWS
over Ethernet, Wi-Fi GRE, and Quectel/WireGuard F1.

## Current status

All supported TUI configurations are working:

| Access DU | Ethernet | Wi-Fi GRE | Quectel/WireGuard |
|---|---:|---:|---:|
| MiniPC | Working | Working | Working |
| Raspberry Pi | Working | Working | Working |
| Jetson | Working | Working | Working |

The firecell monolithic reference, PWS/SIB8 flow, phone registration, PDU
session, internet, throughput checks, stop, and Ethernet rollback are also
working.

## Quick start

Requires Node.js 18+, OpenSSH, lab network access, SSH keys, and the private
`lab.env` file.

```bash
git clone https://github.com/promaaa/oai-cu-du-lab.git
cd oai-cu-du-lab
mkdir -p conf/local
cp /path/to/lab.env conf/local/lab.env
chmod 600 conf/local/lab.env
./oai-lab --check-local-setup
./oai-lab
```

Install Node.js on macOS with `brew install node`. The env file may also remain
outside the repository:

```bash
./oai-lab --env="$HOME/private/lab.env"
```

See [conf/lab.env.example](conf/lab.env.example) for all available settings.
Use the [clean-clone redeployment test](REDEPLOYMENT.md) for a staged
`oai-pc` and macOS handover rehearsal.

## Useful commands

```bash
./oai-lab --check-local-setup
./oai-lab --status
./oai-lab --logs

./oai-lab --minipc-ethernet --start-ethernet
./oai-lab --pi-wifi-gre --start-wifi-gre
./oai-lab --jetson-quectel-wg --start-quectel-wg
./oai-lab --start-mono
```

The interactive TUI exposes every DU/transport combination, PWS text updates,
status, logs, and clean stop/rollback actions.

## Notes

- Obtain exclusive lab ownership before launching or stopping a scenario.
- Confirm that the required B210 is physically connected to each radio host;
  the TUI discovers its serial live and generates the runtime config accordingly.
- Use MiniPC Ethernet CU/DU as the rollback configuration.
- Do not commit the private env file, credentials, subscriber data, keys,
  generated configs, raw logs, or packet captures.
- Runtime evidence is stored under `~/.local/state/oai-cu-du-lab/runs/`.
- `./oai-lab` is the only supported operator entry point; files under
  `scripts/lib/` are internal implementation details.
- Run local checks with `node scripts/tests/oai-lab-static.test.mjs`.
- Additional operator information is available in the [wiki](wiki/index.html).
