# Troubleshooting and recovery

## First rule

Do not restart everything immediately. Capture current process, core, route,
tunnel, radio, and phone state, then change the smallest responsible layer.

| Symptom | Likely boundary | First check |
|---|---|---|
| PWS appears but no 5G service | phone camping/broadcast path only | watch RACH and `INITIAL_UL_RRC` after one airplane-mode toggle |
| UE registers but no PDU session | core discovery or DNN | inspect AMF/SMF/NRF before restarting only the failing service |
| PDU exists but phone has no internet | user plane, APN, NAT, or stale bearer | confirm live UE IP and external-DN ping |
| Jetson ping loss or overflow | USB IRQ, runtime, or RF stability | verify B210 `5000M`, active xHCI IRQ affinity, overflow delta |
| B210 appears at `480M` | pre-firmware enumeration or USB2 path | run UHD probe and confirm runtime re-enumeration at `5000M` |
| X310 106 PRB overflows | transport ceiling | verify negotiated link rate before changing RF parameters |
| F1 appears on wrong interface | stale route/tunnel/process | stop through TUI, inspect routes and sockets, then relaunch |
| Menu differs from source | stale TUI process | stop the old local Node process and start the maintained script |

## Recovery order

1. Stop the selected scenario through the TUI.
2. Confirm which softmodem and core processes remain.
3. Remove only scenario-owned temporary firewall, tunnel, and MTU changes.
4. Preserve management access.
5. Restore the MiniPC Ethernet profile.
6. Revalidate machine gates, then phone gates.

Never delete host trees, local configuration, or raw evidence merely because a
directory name looks old. Establish ownership and rollback first.
