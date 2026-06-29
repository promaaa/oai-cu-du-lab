# Research Progress Report 20

Date: 2026-06-28
Author: Antigravity Lab Agent

## Executive Summary

This report documents the resolution of the end-to-end user plane data connectivity issue on the Raspberry Pi 5 DU + USRP B210 (106 PRB) Ethernet split baseline. Following the fix for core routing and NAT masquerading, user plane internet connectivity was restored and verified on the Nothing Phone commercial UE.

## Key Performance Results

- **Observed User Throughput (Ethernet F1 Baseline)**: **6.1 Mbps** (measured on Nothing Phone 5G data connection).
- **Observed User Throughput (Wi-Fi GRE F1 Baseline)**: **2.5 Mbps** (initial run without MCS floor tuning).
- **Observed User Throughput (Wi-Fi GRE F1 Tuned)**: **52 Mbps** (measured on Nothing Phone 5G data connection with forced MCS 10-28 and expanded BLER target window).
- **Radio Access**: USRP B210 serial `8002816` running at `46.08 MSps` (106 PRB) on `serber-pi` with `overflow_count=0`.
- **Core Network & PWS**: SIB8/PWS broadcasting confirmed; PDU session established with IP allocation and internet access verified across Ethernet and Wi-Fi GRE backhauls.

## Infrastructure & Software Fixes Applied

1. **WAN Routing Fix**: Corrected stale default gateway on `serber-firecell` to point to `10.76.170.126 dev enp6s0`.
2. **UE Subnet NAT Masquerading**: Added persistent NAT MASQUERADE rule for UE subnet `10.0.0.0/16` on `serber-firecell`.
3. **CU SCTP Binding Fix**: Updated `prepareCuRuntimeConfig` in `scripts/oai-lab-tui` to substitute `local_s_address` / `remote_s_address` in addition to `local_n_address` / `remote_n_address`, allowing CU SCTP listening sockets to bind correctly to non-Ethernet overlay interfaces (e.g., Wi-Fi GRE `10.255.0.1`).
4. **MAC Scheduler MCS & BLER Tuning**: Applied expanded BLER target window (`dl_bler_target_upper=0.35`, `dl_bler_target_lower=0.25`) and forced MCS range (`10` to `28`), enabling the live radio on the Wi-Fi backhaul to unlock higher-order modulation (64QAM/256QAM) and jump from 2.5 Mbps to **52 Mbps**.
5. **TUI Automation**: Integrated `ensureUpfRoutingAndNat()` into `scripts/oai-lab-tui` (`waitForSplitCoreReady` and split startup) to guarantee persistent WAN routing and NAT configuration on every split core launch.

## Next Objectives

- Initiate Quectel 5G/WireGuard backhaul profile configuration and validation.
