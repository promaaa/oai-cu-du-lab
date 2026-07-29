# Clean-clone redeployment test

This rehearsal tests the operator console from a fresh clone. It does not
reinstall OAI on the radio hosts and it must not disturb an existing checkout
or running scenario.

## What this test proves

Run the first rehearsal on `oai-pc` through AnyDesk. Because `oai-pc` is on the
lab network, it proves that a clean Linux operator workstation can load the
private configuration, reach the configured hosts, and open the maintained
TUI.

A later MacBook rehearsal proves the same local console setup on macOS. It also
requires a working lab route, such as an approved VPN or an approved SSH jump
path. AnyDesk access to `oai-pc` does not by itself give the MacBook a route to
the private `10.76.170.0/24` lab network.

Neither rehearsal is a radio scenario PASS. A scenario PASS still requires the
machine and phone gates in the acceptance record below.

## Safety boundary

Before using a launch or stop action:

1. obtain exclusive ownership of the shared lab;
2. confirm which host physically owns each required B210;
3. record the currently running configuration;
4. keep MiniPC Ethernet CU/DU as the rollback target.

The initial clean-clone and SSH checks below are read-only. Do not copy secrets,
raw logs, packet captures, generated configs, or private keys into the clone.

## Phase A: clean clone on `oai-pc`

Open a terminal inside the AnyDesk session and run:

```bash
whoami
hostname
uname -a
command -v git
command -v ssh
command -v node
node --version
```

Node.js 18 or newer is required. On Ubuntu, install missing base packages with:

```bash
sudo apt-get update
sudo apt-get install -y git openssh-client nodejs
node --version
```

If the packaged Node.js major version is below 18, install a current Node.js
LTS release using the workstation's approved package source before continuing.

Use a new directory so this test cannot overwrite another checkout:

```bash
test ! -e "$HOME/oai-cu-du-lab-redeploy-test"
git clone --depth 1 https://github.com/promaaa/oai-cu-du-lab.git \
  "$HOME/oai-cu-du-lab-redeploy-test"
cd "$HOME/oai-cu-du-lab-redeploy-test"
git status --short --branch
git rev-parse HEAD
```

The repository is private. If Git requests authentication, use the approved
GitHub credential flow; do not paste or store a token in a tracked file.

Create the ignored local configuration from the tracked template:

```bash
mkdir -p conf/local
install -m 600 conf/lab.env.example conf/local/lab.env
./oai-lab --check-local-setup
```

If the lab uses values different from the tracked defaults, edit only
`conf/local/lab.env`. Keep its mode at `600`. Do not add UE authentication
values, passwords, private keys, or tokens unless an existing approved private
configuration explicitly requires them.

Run the dependency-free test before contacting the lab:

```bash
node scripts/tests/oai-lab-static.test.mjs
```

Then prove SSH discovery for the rollback profile:

```bash
./oai-lab --minipc-ethernet --verify
```

This gate passes only when the console reaches `serber-firecell` and discovers
`serber-minipc`. If it fails, do not launch. Check the exact SSH target from the
same terminal, for example:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 serber@10.76.170.38 hostname
ssh -o BatchMode=yes -o ConnectTimeout=8 serber@10.76.170.40 hostname
```

Fix the workstation SSH agent/key or the local host values without weakening
host authentication globally.

## Phase B: read-only TUI rehearsal

Start the console:

```bash
./oai-lab
```

In the first screen:

1. choose `serber-minipc`;
2. confirm the displayed Core/CU and DU values;
3. in the main menu, choose `View live host/process/core status`;
4. return and choose `View recent OAI logs and milestones`;
5. return and choose `Exit`.

Do not choose a launch, PWS update, or stop action during this read-only
rehearsal. This phase passes when the fresh clone opens the current menu, shows
the selected hosts, reads status/log summaries, and exits cleanly.

## Phase C: controlled rollback launch

Run this phase only with exclusive lab ownership, the B210 physically connected
to the MiniPC, and no scenario that must be preserved.

1. Open `./oai-lab` and choose `serber-minipc`.
2. Choose `Launch Ethernet F1 CU/DU split`.
3. Keep the terminal visible until the machine-side gates finish.
4. On the lab phone, toggle airplane mode once and separately record PWS,
   registration, PDU session, internet, downlink, and uplink results.
5. Return to the TUI and inspect status and logs.
6. Choose `Stop the current config` and wait for management access confirmation.

Private run evidence is written under:

```text
~/.local/state/oai-cu-du-lab/runs/
```

Do not copy that directory into Git. Only a sanitized conclusion may be added
to the repository after review.

## Phase D: professor's MacBook

Once the MacBook is on an approved network path to the lab, repeat the test in
a new directory:

```bash
xcode-select -p >/dev/null || xcode-select --install
command -v brew >/dev/null || echo "Install Homebrew from its official site"
brew install node
git clone --depth 1 https://github.com/promaaa/oai-cu-du-lab.git \
  "$HOME/oai-cu-du-lab-redeploy-test"
cd "$HOME/oai-cu-du-lab-redeploy-test"
mkdir -p conf/local
install -m 600 conf/lab.env.example conf/local/lab.env
./oai-lab --check-local-setup
node scripts/tests/oai-lab-static.test.mjs
./oai-lab --minipc-ethernet --verify
./oai-lab
```

The MacBook rehearsal is successful only after both the local setup check and
live SSH discovery pass. A successful `oai-pc` rehearsal cannot substitute for
the MacBook network gate.

## Acceptance record

Record only these sanitized results in the handover notes:

| Gate | Result |
|---|---|
| Fresh clone and exact Git commit recorded | `PASS` / `FAIL` |
| Node.js 18+ and OpenSSH | `PASS` / `FAIL` |
| Private env loaded with mode `600` | `PASS` / `FAIL` |
| Static suite | `PASS` / `FAIL` |
| Firecell SSH | `PASS` / `FAIL` |
| MiniPC discovery | `PASS` / `FAIL` |
| Read-only TUI status/log/exit | `PASS` / `FAIL` |
| Ethernet machine gates | `PASS` / `FAIL` / `NOT RUN` |
| Phone PWS | `PASS` / `FAIL` / `NOT RUN` |
| Registration and PDU session | `PASS` / `FAIL` / `NOT RUN` |
| Phone internet and timestamped DL/UL | `PASS` / `FAIL` / `NOT RUN` |
| Clean stop and Ethernet rollback | `PASS` / `FAIL` / `NOT RUN` |
