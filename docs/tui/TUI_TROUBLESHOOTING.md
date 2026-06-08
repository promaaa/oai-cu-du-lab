# TUI Troubleshooting

## The TUI Cannot SSH

Run:

```bash
./scripts/oai-lab-tui --verify
```

The TUI bypasses the broken local host aliases and uses direct SSH targets:

```text
serber-firecell = serber@10.76.170.38
serber-minipc   = serber@10.76.170.100
```

The launcher uses `BatchMode=yes`, so password prompts fail fast instead of
hanging during a demo.

## A Scenario Does Not Start

Common causes are:

- SSH unavailable.
- `sudo -n` requires a password.
- OAI config file missing.
- OAI binary missing.
- USRP is not detected.
- Core Docker compose path differs from the hard-coded demo path.
- Both monolithic and split core containers are running on `serber-firecell`.


## Minipc DU Fails F1 Setup

During live testing, a stale `oai-pc` DU at `10.76.170.90` was already attached
to the CU and used the same DU identity. The Ethernet startup path now adds a
temporary CU-side SCTP drop rule for that peer before starting the minipc DU.
Select `Stop the current config` to stop the split stack and remove the rule.

## Phone Registers But Has No Internet

Check that only the split core containers are active for the split demo. The
Ethernet startup path now stops the firecell monolithic core before starting
`oai-cn5g-minipc-*`, because running both OAI CN stacks at once can confuse
user-plane troubleshooting.

Also check the phone APN/DNN. During live debugging, the CU/DU path reached RRC
connected and the AMF selected the UE, but SMF reported DNN/subscription/context
warnings. Set the Nothing Phone APN to `oai`, toggle airplane mode, and then
watch the CU/DU log files for PDU session setup.

## PWS Text Does Not Change On The Phone

The current SIB8 implementation reads `sib8.conf` during process startup.
After applying a PWS message in the TUI, restart the relevant monolithic or
split scenario and record a phone observation in the run notes.
