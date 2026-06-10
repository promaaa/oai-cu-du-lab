# TUI Discovered Commands

Discovery date: 2026-06-01.

This file records only non-secret operational facts. Raw logs, packet captures,
passwords, subscriber material, and UE authentication values remain excluded.

## SSH Reachability

| Target | Result |
|---|---|
| `serber@10.76.170.38` | Reached `serber-firecell`. |
| `serber@10.76.170.100` | Reached `serber-minipc`. |
| `serber-pi` | SSH timed out to `10.76.170.94`. |
| `oai-pc` | Hostname did not resolve in the current local environment. |
| `10.76.170.90` | Observed as a stale F1 peer on the CU during Ethernet rollback testing. |

The current local SSH aliases `serber-firecell` and `serber-minipc` both
resolve to `10.85.168.144` through the local SSH config. The demo TUI therefore
hard-codes direct `serber@10.76.170.38` and `serber@10.76.170.100` targets.

## External OAI Repositories

Observed OAI commit where Git metadata was available:

```text
102965a669b9444857c27843ec8ce62780bf9d37
```

Observed external trees include:

```text
/home/serber/monolithic/openairinterface5g
/home/serber/cu-du/source/openairinterface5g
/home/serber/cu-du-backhaul/source/openairinterface5g
/home/serber/cu-du-minipc-backhaul/source/openairinterface5g
```

The working trees include local SIB8/PWS modifications. The canonical repo
keeps those changes as `patches/sib8/oai-pws-sib8-cu-du.patch`; do not vendor
the OAI source tree here.

## SIB8/PWS Config Files

Observed SIB8 files:

```text
/home/serber/monolithic/openairinterface5g/sib8.conf
/home/serber/cu-du/source/openairinterface5g/sib8.conf
/home/serber/cu-du-backhaul/source/openairinterface5g/sib8.conf
/home/serber/cu-du-minipc-backhaul/source/openairinterface5g/sib8.conf
```

The patch reads `../../../sib8.conf` from the softmodem build directory, so
changing warning text requires updating the external OAI `sib8.conf` and
restarting the running gNB/CU/DU process for the selected scenario.

## Currently Observed Runtime

During discovery, `serber-firecell` had `nr-softmodem` processes running with:

```text
/home/serber/cu-du-minipc-backhaul/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-cu-oai-pc.conf
```

The TUI now treats startup as an explicit stop-and-relaunch demo action for the
selected scenario. `Start Ethernet CU/DU rollback baseline` stops existing
`nr-softmodem` processes on the CU and DU hosts before starting the rollback
baseline, matching the way the previous working `5g-tui` handled monolithic
startup.

Live Ethernet rollback testing also found that a stale `oai-pc` DU could attach
to the CU before the minipc DU and cause an F1 setup rejection. The TUI therefore
adds a temporary CU-side SCTP drop rule for `10.76.170.90` while the minipc
rollback scenario is running. The `Stop Ethernet CU/DU` action removes that
temporary rule.

Monolithic startup is pinned to `serber-firecell` to match the existing
monolithic demo workflow. If firecell cannot see a USRP at runtime, the TUI
fails that start explicitly instead of silently moving monolithic to another
host.

Ethernet split testing also found duplicate OAI core stacks on firecell:
plain `oai-*` monolithic containers and `oai-cn5g-minipc-*` split containers.
The Ethernet startup path now stops the monolithic core and restarts the split
core before starting CU/DU.

Phone-data debugging on 2026-06-01 showed the UE reaching RRC connected and the
AMF, while SMF reported DNN/subscription/context warnings. The demo procedure
therefore calls out the `oai` APN/DNN requirement before phone validation.

## Blocked Workflows

`serber-pi` is not operational in this environment because SSH did not connect.
Before enabling launch actions, record SSH status, USRP detection, DU startup,
CPU/RAM, temperature, throttling, logs, and failure reasons.

`oai-pc` is not operational in this environment because the hostname did not
resolve. Before enabling launch actions, record the target address, repository
paths, config files, interfaces, USRP visibility, launch commands, and stop
commands.

The nrUE internet-through-radio workflow remains blocked until exact validated
gNB and nrUE commands are recovered. The TUI provides read-only preflight and
evidence capture helpers, but does not claim this scenario is operational.
