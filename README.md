# OAI CU/DU Lab

Operator tooling for an OpenAirInterface 5G NR CU/DU split lab with
SIB8/Public Warning System support.

## At a glance

| Category | Configuration |
|---|---|
| Access DUs | MiniPC, Raspberry Pi, Jetson |
| F1 transports | Ethernet, Wi-Fi/GRE, Quectel/WireGuard |
| Access radio | USRP B210 |
| Workflows | Split CU/DU, monolithic reference, PWS updates, validation, rollback |
| Operator interface | `./oai-lab` |

## Companion projects

| Repository | Role |
|---|---|
| [`promaaa/jetson-kernel-sctp`](https://github.com/promaaa/jetson-kernel-sctp) | SCTP-enabled kernel provisioning for the Jetson DU |

This repository is the operational source of truth. OpenAirInterface source
remains external and is pinned for each deployment.

## Research artifact and components

- [`docs/PDFs/research-paper.tex`](docs/PDFs/research-paper.tex) is the research
  paper LaTeX source; the PDF manuscript is
  [`docs/PDFs/research-paper.pdf`](docs/PDFs/research-paper.pdf).
- [`conf/pws-sib8.example`](conf/pws-sib8.example) provides the public,
  test-only warning profile without subscriber or infrastructure data.
- [`patches/sib8/`](patches/sib8/) contains the F1 CU/DU SIB8/PWS patch.
- [`patches/performance/`](patches/performance/) contains the DL MCS scheduler
  instrumentation and jumbo frames guide.
- [`patches/rpi-du/`](patches/rpi-du/) contains the Raspberry Pi DU B210 sample
  rate patch.
- [`wiki/`](wiki/) provides the operator guides, topology reference, and
  validation workflows.

## Quick start

Requirements: Node.js 18+, OpenSSH, lab network access, SSH keys, and a private
`lab.env` based on [`conf/lab.env.example`](conf/lab.env.example).

```bash
git clone https://github.com/promaaa/oai-cu-du-lab.git
cd oai-cu-du-lab
mkdir -p conf/local
install -m 600 /path/to/lab.env conf/local/lab.env

./oai-lab --check-local-setup
./oai-lab
```

To keep the environment file outside the clone:

```bash
./oai-lab --env=/absolute/private/path/lab.env
```

## Operator commands

| Task | Command |
|---|---|
| Local preflight | `./oai-lab --check-local-setup` |
| Lab connectivity | `./oai-lab --verify` |
| Current state | `./oai-lab --status` |
| Recent logs | `./oai-lab --logs` |
| Interactive console | `./oai-lab` |

Example non-interactive launch:

```bash
./oai-lab --minipc-ethernet --start-ethernet
```

Run `./oai-lab --help` for every DU, transport, and action.

## Operational safeguards

- Obtain exclusive lab ownership before starting, stopping, or rolling back.
- Confirm the required B210 is connected to the selected radio host.
- Keep MiniPC Ethernet CU/DU available as the rollback baseline.
- Never commit credentials, subscriber data, keys, generated configs, raw
  logs, or packet captures.
- Store runtime evidence under `~/.local/state/oai-cu-du-lab/runs/`.

For detailed procedures, see the [redeployment guide](REDEPLOYMENT.md) and
[operator wiki](wiki/index.html).
