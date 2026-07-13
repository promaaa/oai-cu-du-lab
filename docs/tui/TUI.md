# Operator TUI

Run:

```bash
./scripts/oai-lab-tui
```

The console is a dependency-free Node prompt TUI modeled after the working
`5g-tui` monolithic launcher. It uses boxed headers, numbered menus, and
step-by-step status output instead of the previous curses scroll screen.

Before the main menu, the TUI shows the active lab configuration and any
detected running OAI config on `serber-firecell`. The operator can keep the
current environment/default config or choose one of the known DUs:

```text
serber-minipc = serber@10.76.170.40
serber-pi     = serber@10.76.170.18
serber-jetson = serber@10.76.170.8
```

After selecting the DU, the TUI asks for the shared CU/DU F1 config:

- Ethernet F1;
- Wi-Fi GRE F1;
- Quectel 5G/WireGuard F1.

The same screen can also build a custom `serber-firecell` + selected-DU
configuration from operator-supplied SSH targets or IP addresses. CU/DU launch
actions discover the selected DU management path at runtime.
Legacy caged Quectel donor actions remain gated and must still produce live
modem, WireGuard, F1, phone-service, and rollback evidence before any PASS.

## Quick Check

```bash
./scripts/oai-lab-tui --verify
```

## PWS/SIB8 Message Manager

The PWS/SIB8 manager updates every TUI-managed warning-message config in one
operation. That includes:

- firecell monolithic OAI;
- firecell split/caged CU OAI;
- live selected-DU split/caged DU OAI;
- compatibility copies under the related scenario roots and `conf/`
  directories.

The TUI records the updated remote paths in the local evidence directory for
the message update. A scenario restart is still required before the new warning
text is broadcast, because OAI reads `sib8.conf` during process startup.

The caged Quectel monolithic-donor actions also support direct launch and retry:

```bash
./scripts/oai-lab-tui --start-caged-quectel
./scripts/oai-lab-tui --validate-caged-quectel
./scripts/oai-lab-tui --rollback-caged-quectel
```

Unified DU/config CLI shortcuts:

```bash
./scripts/oai-lab-tui --du=serber-minipc --backhaul=ethernet --start-ethernet
PI_WIFI_IP=<du-wifi-ip> ./scripts/oai-lab-tui --du=serber-pi --backhaul=wifi-gre --start-wifi-gre
./scripts/oai-lab-tui --du=serber-jetson --backhaul=quectel-wg --start-quectel-wg
```

Older Raspberry Pi shortcut aliases still work:

```bash
./scripts/oai-lab-tui --pi-ethernet --start-ethernet
PI_WIFI_IP=<pi-wifi-ip> ./scripts/oai-lab-tui --pi-wifi-gre --start-wifi-gre
./scripts/oai-lab-tui --pi-quectel-wg --start-quectel-wg
```

The Wi-Fi GRE profile uses `GRE_NAME=test-gre`,
`GRE_CU_INNER_IP=10.255.0.1`, and `GRE_DU_INNER_IP=10.255.0.2` unless
overridden in `conf/local/lab.env`.

Split DU runtime generation uses a less conservative scheduler profile than
stock OAI so the live B210 cell can climb instead of camping at MCS 0:
DL BLER target `0.45..0.65`, UL BLER target `0.25..0.45`,
`SPLIT_DL_MIN_MCS=10`, `SPLIT_DL_MAX_MCS=18`, `SPLIT_UL_MIN_MCS=5`, and
`TCP_MSS_CLAMP=1200` by default. Use `DL_MIN_MCS`/`UL_MIN_MCS` and
`DL_MAX_MCS`/`UL_MAX_MCS` for per-direction overrides, or `--force-mcs` for the
stronger asymmetric floor. The Pi DU profile additionally defaults to a more
robust UL/control profile: `UL_PUSCH_TARGET_SNR_X10=170`,
`UL_PUCCH_TARGET_SNR_X10=240`, `UL_P0_NOMINAL_WITH_GRANT=-86`,
`UL_PUCCH_P0_NOMINAL=-86`, `PUCCH0_DTX_THRESHOLD=140`, and
`PRACH_DTX_THRESHOLD=180`; each value can be overridden from the environment.

## Supported Starts

- Ethernet CU/DU with SIB8 rollback baseline.
- Monolithic reference on `serber-firecell`, matching the existing demo
  workflow.
- Caged Quectel F1 Backhaul, Monolithic Donor, using
  `docs/quectel-f1-backhaul/single-cu-firecell-donor-launch-runbook.md` as a
  gated launch sequence.

The main menu intentionally shows only the operator-ready workflows:

- launch the selected CU/DU config on the selected DU;
- change the selected DU/config;
- launch monolithic firecell core + gNB;
- launch or validate caged Quectel F1 backhaul with monolithic donor;
- change PWS/SIB8 warning text everywhere;
- view live status/logs;
- stop the current config.

Experimental preflight helpers for Raspberry Pi DU, `oai-pc`, nrUE, and older
Experimental showcase checks remain in the script but are hidden from the main
operator menu until they have current validation evidence.

## Ethernet CU/DU Rollback Baseline

The CU/DU startup action discovers the selected DU SSH target,
management source IP, and selected F1 transport before launching the split. It
builds temporary `/tmp/oai-tui-gnb-*-runtime.conf` files from the checked-in CU
and DU configs and patches only the runtime copies with the live F1 addresses.

The TUI gates the CU/DU run in this order:

1. Host and selected DU discovery.
2. Selected-DU radio preflight before changing lab state.
3. Previous OAI softmodem stop.
4. Conflicting monolithic core stop.
5. Competing `oai-pc` F1 isolation.
6. DU USRP confirmation after cleanup.
7. Selected F1 transport preparation.
8. Split core startup.
9. CU/DU runtime config generation.
10. CU startup.
11. DU startup.
12. F1/PWS milestone validation.
13. Packet validation.
14. Phone prompt and core health.

The Ethernet startup action stops existing `nr-softmodem` processes on the
selected CU/DU hosts before launching the rollback baseline, matching the demo
workflow.

For the current professor-demo hardware, Ethernet startup also stops the
firecell monolithic core containers before starting the split core. This avoids
having both plain `oai-*` containers and `oai-cn5g-minipc-*` containers active
during the split demo. It restarts the split core cleanly, then adds a
temporary CU-side iptables rule that drops SCTP/F1 traffic from the stale
`oai-pc` peer at `10.76.170.90`. This prevents the old `gNB-DU-OAI-PC` process
from claiming the same DU identity before the minipc DU attaches. `Stop the current config` removes that temporary rule.

The CU/DU scenario prints **PASS** only after F1 setup, SIB8/PWS
delivery, DU radio sync, F1-C SCTP on the selected transport, and no F1-C or
F1-U leakage on the non-selected paths is visible.

For Raspberry Pi runs, the selected-DU radio preflight must show the local USB
B210 through UHD. If a currently running softmodem owns the radio, the TUI
accepts the USB presence only as a temporary preflight signal, stops the old
softmodem, and then requires UHD visibility before any CU/DU launch.

The Ethernet CU/DU profile remains the rollback baseline only when run on the
validated baseline hardware. Wi-Fi GRE fails closed if `serber-firecell` cannot
reach the selected DU Wi-Fi IP before creating the tunnel. Quectel/WireGuard
fails closed if QMI shows the SIM is not initialized, the modem is not
packet-registered, or no live PDU IP/gateway is available.

## Monolithic Reference

The monolithic firecell action is also gated:

```bash
./scripts/oai-lab-tui --start-mono
```

Before startup, the TUI discovers the selected DU, stops split CU/DU
softmodems, removes the temporary `oai-pc` F1 isolation rule, and stops the
split-core containers so the monolithic `oai-*` core is the only active core.

The monolithic scenario prints **PASS** only after these gates pass:

- Firecell B210 is detected.
- Monolithic core containers start.
- Monolithic gNB process remains running.
- AMF/gNB NG setup is visible.
- SIB8/PWS and radio sync are visible in the monolithic gNB log.
- No live selected-DU process, split-core containers, Ethernet split F1, or
  `wg-quectel-f1` F1 traffic remains visible.

The Raspberry Pi DU, `oai-pc` DU, and nrUE internet-through-radio workflows are
preflight/discovery only until the real commands and validation evidence are
recorded.

## Caged Quectel F1 Backhaul, Monolithic Donor

The Quectel scenario does not use the older fixed minipc management target
for launch decisions. It discovers the live `serber-minipc` SSH target,
management source IP, and management interface at runtime, then discovers the
Quectel data interface, QMI device, PDU IP, prefix, and gateway from live modem
state. Supply the local subscriber profile with `QUECTEL_IMSI=<imsi>` or enter
it at the TUI prompt; the TUI sanitizes the provisioning evidence and does not
write subscriber secrets to Git.

The TUI gates the run in this order:

1. Hardware preflight.
2. Firecell core.
3. Quectel subscriber provisioning in the active split core.
4. Generate CU/DU configs using the external generator script.
5. Start firecell monolithic donor gNB.
6. Quectel donor registration reset and validation of PCI 1 / TAC 2.
7. Quectel QMI/PDU.
8. Routes.
9. WireGuard.
10. Validate independent donor path (PCI/TAC/IP/routes/ping gates).
11. Start firecell CU bound to `10.250.0.1`.
12. Start minipc access DU over WireGuard.
13. Packet validation.
14. UE/F1-U validation and rollback readiness.

The donor gate uses the firecell monolithic donor gNB config with PCI `1` and
TAC `2`. The WireGuard gate updates the peer hooks from the live Quectel PDU
address and gateway before restarting `wg-quectel-f1`.

The firecell donor gNB and split CU may run together, so Quectel start and
stop functions target only the relevant config paths. They do not kill
all firecell `nr-softmodem` processes.

The scenario prints **PASS** only after all required packet gates pass:

- F1-C SCTP is visible on `wg-quectel-f1`.
- WireGuard outer UDP is visible on the discovered Quectel data interface.
- F1-U `UDP/2153` is visible on `wg-quectel-f1` during phone traffic.
- Discovered management Ethernet/WiFi interfaces carry no F1-C or F1-U during
  validation windows.

The UE/F1-U gate gives the operator three phone-traffic attempts. If no
`UDP/2153` appears on `wg-quectel-f1`, the TUI fails closed and records
`No PASS claimed`.

If the split is already running and only phone traffic needs another attempt,
use `Validate caged Quectel F1 backhaul, monolithic donor` or
`./scripts/oai-lab-tui --validate-caged-quectel`. That action refreshes the
live Quectel PDU routes and WireGuard tunnel, runs the independent donor check,
rechecks packet placement, then reruns the F1-U gate without restarting the donor, CU, or DU.

## Evidence

Every action creates an ignored local run directory under:

```text
experiments/YYYYMMDD_HHMMSS_<scenario>_<action>/
```

The directory contains logs, measurements, and system-status snippets where the
selected action captures them. Sanitize before committing any excerpts.
