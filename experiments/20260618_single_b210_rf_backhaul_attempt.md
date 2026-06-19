# Single-B210 RF Backhaul Attempt

Date: 2026-06-18

## Requested Action

Apply the temporary single-B210 RF backhaul experiment plan on `serber-minipc`:

- suppress Quectel/WireGuard for the experiment;
- probe USRP B210 serial `8002816`;
- keep Ethernet CU/DU with SIB8 as rollback;
- do not claim success without sanitized evidence.

## Result

Blocked before hardware or OAI validation.

The experimental TUI mode was run:

```bash
./scripts/oai-lab-tui --experimental-b210
```

It failed closed during Step 1, minipc discovery:

```text
serber-minipc SSH target is required for the experimental single-B210 mode
No PASS claimed.
```

Because discovery failed before Step 2, the run did not suppress Quectel,
stop remote OAI processes, write remote runtime files, or modify any live
remote configuration.

## Reachability Evidence

Direct SSH from the operator machine:

```text
ssh: connect to host 10.76.170.100 port 22: Operation timed out
```

Reachability from `serber-firecell`:

```text
PING 10.76.170.100: 100% packet loss
ip route get 10.76.170.100: dev enp6s0 src 10.76.170.38
ip neigh show 10.76.170.100: FAILED
```

The firecell management interface was up:

```text
enp6s0 UP LOWER_UP
10.76.170.38/25 on enp6s0
```

## Interpretation

`serber-minipc` was not reachable on the documented management address
`10.76.170.100` from either the operator machine or `serber-firecell`.
The failed neighbor/ARP state means the host was not visible on the expected
local management segment at the time of the attempt.

## Next Physical Checks

1. Confirm `serber-minipc` is powered on and booted.
2. Confirm its management Ethernet cable is connected to the expected lab
   network.
3. On the minipc console, verify its active IP address and SSH service:

```bash
ip -4 -br addr
systemctl status ssh
```

4. If the minipc IP changed, update the TUI lab configuration before rerunning:

```bash
./scripts/oai-lab-tui --experimental-b210
```

Only after minipc SSH works should the plan proceed to B210/UHD probing and
the no-Quectel packet gates.
