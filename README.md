# OAI CU/DU Lab

Operator repository for an OpenAirInterface 5G NR CU/DU split lab with
SIB8/Public Warning System support.

`./oai-lab` runs MiniPC, Raspberry Pi, and Jetson access DUs over Ethernet,
Wi-Fi/GRE, or Quectel/WireGuard F1. It also provides a monolithic reference,
status and log inspection, PWS updates, and Ethernet rollback.

Lab results are scenario-specific. A successful machine-side launch is not a
full PASS without fresh phone-visible PWS, registration, data, throughput, and
rollback evidence.

## Related repositories

- [`promaaa/jetson-kernel-sctp`](https://github.com/promaaa/jetson-kernel-sctp)
  provides the SCTP-enabled kernel required by the Jetson DU.
- [`promaaa/kaust-5G-research`](https://github.com/promaaa/kaust-5G-research)
  contains research reports, figures, and historical experiment context.

This repository remains the operational source of truth. OpenAirInterface
source is kept external and pinned for each deployment.

## Quick start

Requires Node.js 18+, OpenSSH, lab network access, SSH keys, and a private
`lab.env` based on [`conf/lab.env.example`](conf/lab.env.example).

```bash
git clone https://github.com/promaaa/oai-cu-du-lab.git
cd oai-cu-du-lab
mkdir -p conf/local
install -m 600 /path/to/lab.env conf/local/lab.env

./oai-lab --check-local-setup
./oai-lab
```

The environment file may remain outside the repository:

```bash
./oai-lab --env=/absolute/private/path/lab.env
```

## Common commands

```bash
./oai-lab --verify
./oai-lab --status
./oai-lab --logs

./oai-lab --minipc-ethernet --start-ethernet
./oai-lab --pi-wifi-gre --start-wifi-gre
./oai-lab --jetson-quectel-wg --start-quectel-wg
./oai-lab --start-mono
```

Run `./oai-lab --help` for all options.

## Operating rules

- Obtain exclusive lab ownership before starting, stopping, or rolling back.
- Confirm the required USRP B210 is connected to the selected radio host.
- Keep MiniPC Ethernet CU/DU available as the rollback baseline.
- Never commit credentials, subscriber data, keys, generated configs, raw
  logs, or packet captures.
- Store runtime evidence under `~/.local/state/oai-cu-du-lab/runs/`.

See [REDEPLOYMENT.md](REDEPLOYMENT.md) for clean-clone setup and the
[operator wiki](wiki/index.html) for detailed procedures.
