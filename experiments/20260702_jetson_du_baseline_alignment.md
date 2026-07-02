# Jetson DU Baseline Alignment

Date: 2026-07-02

## Goal

Make the Jetson Orin Nano DU configuration match the documented MiniPC access-DU rollback identity except where the host must differ: management/F1 IP, interface path, launch/runtime tuning, CPU and USB handling, and the live B210 device path.

## Baseline Compared

Source of truth:
- `docs/BASELINES.md`
- `conf/templates/ethernet-du.yml`
- live Jetson runtime `/tmp/oai-tui-gnb-jetson-ethernet-runtime.conf`

The discovered MiniPC file at `/home/serber/cu-du/source/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb-minipc.conf` was not used as the rollback source because it contains older X310/51-PRB values. The repo rollback template keeps the working access-cell strategy: B210 serial `8002816`, PCI `0`, TAC `1`, DU ID `0xe01`, 106 PRB, SSB `641280`, PointA `640008`, `att_tx=3`, and `att_rx=12`.

## Live Jetson Evidence

Sanitized host checks showed:
- Jetson host: `serber@10.76.170.8`
- CU/core host: `serber@10.76.170.38`
- OAI commit on Jetson DU tree: `102965a669b9444857c27843ec8ce62780bf9d37`
- Jetson power mode: `MAXN_SUPER`
- Online CPUs: `0-5`
- B210 USB path: `5000M`
- Running DU launch shape: `sudo -n setsid taskset -c 1-5 ./nr-softmodem -O /tmp/oai-tui-gnb-jetson-ethernet-runtime.conf --log_config.global_log_level warning -E`
- DU overflow count in `/tmp/oai-du-ethernet.log`: `0`
- DU log evidence included F1 UE context and UL RRC message activity.
- SIB8 files compared between Jetson and MiniPC matched byte-for-byte in the checked locations.

## Alignment Changes

Initially changed Jetson DU identity from `0xe02` to the MiniPC access-DU baseline `0xe01` in:
- `conf/templates/jetson-du.yml`
- `scripts/oai-lab-tui` runtime generation

Live recovery showed that `0xe01` regressed the phone-visible service state. The running Jetson DU was restored to `0xe02`, which brought back fresh UE attach activity and phone 5G bars. The repo therefore keeps Jetson `gNB_DU_ID = 0xe02` as a host-specific Jetson exception instead of forcing the MiniPC DU ID.

Kept host-specific differences:
- Jetson F1 local address remains `10.76.170.8`.
- CU peer remains `10.76.170.38`.
- B210 serial remains `8002816`.
- Jetson DU launch keeps `taskset -c 1-5`, `--log_config.global_log_level warning`, and `-E`.
- Jetson runtime remains 106 PRB; no 51-PRB switch was made.

Also added Jetson runtime config paths to the TUI stop list so cleanup handles stale Jetson Ethernet and Quectel/WireGuard runtime processes.

## Regenerated Runtime Check

After the repo changes, the Jetson Ethernet benchmark was regenerated and restarted through:

```bash
./scripts/oai-lab-tui --jetson-ethernet --start-ethernet
```

Sanitized evidence is stored under `experiments/20260702_065255_ethernet_cu_du_rollback_start/`.

Observed gates:
- Runtime config initially showed `gNB_DU_ID = 0xe01`.
- Runtime config kept Jetson F1 local address `10.76.170.8`, CU peer `10.76.170.38`, PointA `640008`, 106 PRB, and B210 serial `8002816`.
- CU/DU logs showed F1 setup response and B210 radio sync.
- DU overflow count remained `0`.
- Ethernet F1-C packet validation passed on the firecell interface.
- Jumbo MTU 9000 path test failed, so the TUI left jumbo frames disabled and used TCP MSS clamping.
- Core logs showed UE registration plus PDU session setup/modification activity.
- Phone-visible service then regressed. The live runtime was restored to `gNB_DU_ID = 0xe02`; the phone regained 5G bars and the UE reattached.
- SIB8/PWS files were aligned to fresh serial `FF09` and CU/DU were restarted. CU logs showed `[SIB8]` and `F1AP_WRITE_REPLACE_WARNING`.
- External-DN ping to database static IP `10.0.0.6` failed because the live UPF PFCP table used UE IP `10.0.0.2`. The first ping to `10.0.0.2` also failed.

## 2026-07-02 Follow-Up Fixes

Two independent Jetson-specific blockers were found and corrected live:

- F1-U port mismatch: the CU used F1-U on `10.76.170.38:2153`, but the Jetson runtime was listening on `10.76.170.8:2152`. The live runtime was corrected to `local_n_portd = 2153` and `remote_n_portd = 2153`, and the TUI Jetson runtime generation now forces those values.
- Missing DU-side PWS patch: CU logs showed `[SIB8]` and `F1AP_WRITE_REPLACE_WARNING`, but the Jetson DU log showed no handler for F1AP procedure code `20`. The repo SIB8/PWS patch was applied to the Jetson OAI checkout without replacing the existing live `sib8.conf`, and `nr-softmodem` was rebuilt.
- Core host routing mismatch: The Core host (`10.76.170.38`) was missing a static route for the UE subnet (`10.0.0.0/16`) pointing to the UPF container IP (`192.168.71.134`). As a result, incoming user-plane replies from the internet were un-masqueraded to the UE IP (`10.0.0.2`) but then routed out to the default gateway (`10.76.170.126`) and dropped. We corrected this by applying `sudo ip route replace 10.0.0.0/16 via 192.168.71.134 dev oai-cn5g-minipc` on the Core host.

Post-fix sanitized evidence:

- Rebuilt Jetson binary contains `DU_handle_WriteReplaceWarning`, `received Write Replace Warning Request from CU`, and PWS/SIB8 scheduling strings.
- Jetson DU restart with the preserved optimized launch showed `local_n_portd = 2153`, `remote_n_portd = 2153`, F1 setup accepted, B210 USB3/radio sync, and overflow count `0`.
- Jetson DU log showed `received Write Replace Warning Request from CU` after F1 setup. The previous `No handler for procedureCode 20` symptom was not repeated.
- UPF recreated the IMS-like `10.0.9.2` session and the data `10.0.0.2` session.
- External-DN ping to live UE IP `10.0.0.2` passed: `5 transmitted, 5 received, 0% packet loss`, with RTT average about `26.5 ms`.
- Firecell NIC capture showed bidirectional F1-U on `10.76.170.38:2153 <-> 10.76.170.8:2153`.
- Core host ping to live UE IP `10.0.0.2` passed: `3 packets transmitted, 3 received, 0% packet loss, time 2002ms` (previously failed with Destination Host Unreachable).

## Status

Pending final user-plane verification (Awaiting phone-visible internet confirmation).

The core routing blocker was identified and fixed. Previously, the Core host was missing a route back to the UE subnet (`10.0.0.0/16`) via the UPF container (`192.168.71.134`), causing un-NAT'ed reply packets to be routed to the external gateway and dropped. 

After adding the route (`sudo ip route replace 10.0.0.0/16 via 192.168.71.134 dev oai-cn5g-minipc`), the Core host successfully pinged the Nothing Phone (`10.0.0.2`) with 0% packet loss. This route addition has been automated in `scripts/oai-lab-tui`.

Verified milestones:
- [x] Host readiness, B210 USB3, zero DU overflows
- [x] DU/CU F1 AP association and bidirectional F1-U on UDP `2153`
- [x] Core PDU-session setup (IMS-like `10.0.9.2` and data `10.0.0.2` recreated)
- [x] External-DN reachability to the live UE data IP
- [x] Phone-visible 5G bars
- [x] Phone-visible PWS alert reception
- [/] Phone-visible internet / user-plane data forwarding to handset (awaiting user verification)

## Next Actions

1. Request the user to verify web browsing and speed test on the Nothing Phone.
2. Once the user confirms working internet, update the status in `inventory/hosts.yml` for `serber-jetson` to `confirmed`.

