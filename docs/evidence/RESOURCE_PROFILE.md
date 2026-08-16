# Sanitized embedded-DU resource profile

Last reconciled: 2026-08-13.

This record publishes minimized resource observations recovered from the
project's dated experiment summaries. Raw logs, host identifiers, radio
serials, addresses, and subscriber material remain outside Git.

## Measured host observations

| Record | Radio profile | CPU | Memory | Temperature | Runtime observation |
|---|---|---:|---:|---:|---|
| `PI4G-51PRB-RESOURCE` | Raspberry Pi 5 4 GB, 51 PRB | load 2.04 on four cores; 54.8% idle | 1.5 GiB / 4.0 GiB used | 67.0 C | no CPU throttling or UHD underruns in the retained sample |
| `PI16G-106PRB-RESOURCE` | Raspberry Pi 5 16 GB, 106 PRB | 181.8%, approximately 1.8 cores | approximately 1.4 GB used | 64.8 C | no late-packet or overflow markers after thread pinning; commercial-UE PWS passed |

These are synchronized resource snapshots inside a repeated operational trial
campaign, not repeated-run averages. They establish that the Raspberry Pi DU
had compute, memory, and thermal headroom in the recorded conditions. They do
not provide a statistically matched comparison with x86 or Jetson. No
equivalent synchronized Jetson CPU, memory, and thermal sample was found, so
none is claimed.

## Electrical planning bounds

The archive contained one-time internal-rail or idle-board readings, but those
did not include the complete compute host, SDR, modem, cooling, USB hub, or DC
conversion path. They are deliberately excluded as payload-power
measurements.

For mechanical and electrical planning, the paper therefore uses transparent
component-based ranges:

| Configuration | Estimated full DC input | Sizing ceiling | Evidence status |
|---|---:|---:|---|
| Raspberry Pi 5 + B210 + Quectel | 19--30 W | 35 W | engineering estimate; radio path validated |
| Jetson Orin Nano + B210 + Quectel | 28--46 W | 50 W | engineering estimate; complete input not measured |

The ranges include an 88% DC-conversion assumption and allowances for the
compute board, SDR, modem, fan, hub, and small interface losses. They must not
be presented as synchronized power or endurance measurements.

External specification bases:

- [Raspberry Pi hardware and power documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#power-supply)
- [NVIDIA Jetson Orin Nano power-mode documentation](https://docs.nvidia.com/jetson/jetpack/6.2/release-notes/index.html)
- [Ettus B200/B210 hardware specifications](https://kb.ettus.com/B200/B210/B200mini/B205mini/B206mini)
- [Quectel RM500Q-GL hardware design](https://forums.quectel.com/uploads/short-url/az7J9yWjD4QD1Q0B7aPfB7ZZImI.pdf)

## Claim boundary

- Repeated end-to-end deployment trials are claimed.
- Mean throughput and per-run dispersion over 20 repetitions per final setup
  are claimed; a matched-condition one-factor cross-setup ranking is not.
- The two Raspberry Pi resource snapshots above are claimed as measured.
- Complete-payload electrical power and flight endurance are not claimed.
- New measurements must record the OAI pin, radio profile, duration, traffic
  state, CPU, memory, temperature, power-meter boundary, and rollback result.
