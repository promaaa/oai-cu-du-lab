# Host Cleanup Report - 2026-06-29

This report records the reversible cleanup pass for `serber-firecell`,
`serber-minipc`, and `serber-pi`.

No files were deleted. All cleanup actions moved candidates into dated
quarantine directories on the same host:

```text
/home/serber/_cleanup_quarantine/20260629/
```

## Evidence

Pre-cleanup inventory:

```text
experiments/20260629_105046_host_cleanup_inventory/
```

Post-cleanup inventory:

```text
experiments/20260629_105254_host_cleanup_inventory/
```

Earlier failed inventory from stale SSH targets:

```text
experiments/20260629_104253_host_cleanup_inventory/
```

## SSH Notes

The local `serber-firecell` SSH alias resolved to `10.85.168.144`, which
identified as `serber-minipc`. This cleanup used direct IPs:

- `serber@10.76.170.38`: `serber-firecell`
- `serber@10.76.170.40`: `serber-minipc`
- `serber@10.76.170.18`: `serber-pi`

The cleanup and inventory used `/tmp/oai_cleanup_known_hosts` so the local user
SSH known-hosts file was not modified.

## serber-pi

Role preserved: active lightweight DU candidate with `/home/serber/cu-du`.

Moved to quarantine:

- `/home/serber/cu-du-archives`
- `/home/serber/monolithic`
- `/home/serber/du.log`
- `/home/serber/pi_start.log`
- `/home/serber/du-minipc.log`
- `/home/serber/.xsession-errors.old`
- attempted `/tmp` runtime/log cleanup where permissions allowed

Post-cleanup state:

- `/home/serber/cu-du/source/openairinterface5g` still exists.
- No OAI softmodem process was running during the cleanup.
- Quarantine size: about `4.6G`.
- Root filesystem still shows about `87%` use because files were quarantined on
  the same partition, not deleted.

Remaining note: `/tmp/gre-debug-pi.pcap` could not be removed from `/tmp`
without elevated permissions. A copy appears under quarantine from the failed
move attempt, but the original still exists.

## serber-minipc

Role preserved: experimental access DU/X310 host with `/home/serber/cu-du`.

Moved to quarantine:

- `/home/serber/cu-du-archives`
- `/home/serber/monolithic`
- old top-level stats logs
- old `/tmp/oai-du-*` runtime logs and generated runtime config from the
  previous X310/51-PRB attempts

Post-cleanup state:

- `/home/serber/cu-du/source/openairinterface5g` still exists.
- No OAI softmodem process was running during the cleanup.
- Quarantine size: about `2.8G`.

## serber-firecell

Role preserved: Core/CU/monolithic/donor host.

Protected paths left in place:

- `/home/serber/monolithic/openairinterface5g`
- `/home/serber/monolithic/oai-cn5g`
- `/home/serber/cu-du-minipc/oai-cn5g-minipc`
- `/home/serber/cu-du-minipc-backhaul/source/openairinterface5g`
- `/home/serber/cu-du`

Moved to quarantine:

- `/home/serber/cu-du-archives`
- `/home/serber/cu-du-benchmark-results`
- old top-level CU/minipc logs
- old `/tmp` donor, same-host, ping-flood, Ethernet/WireGuard, and Quectel logs

Post-cleanup state:

- protected Core/CU/monolithic paths still exist.
- current `/tmp/oai-firecell-donor-monolithic.log` and donor runtime config were
  left in place.
- Quarantine size: about `2.9G`.

Remaining note: `/tmp/gre-debug-firecell.pcap` could not be moved without
elevated permissions.

## Validation Performed

Local syntax:

```bash
bash -n scripts/collect-host-cleanup-inventory.sh
node --check scripts/oai-lab-tui
```

TUI reachability:

```bash
LAB_SSH_OPTS='-o BatchMode=yes -o ConnectTimeout=8 -o UserKnownHostsFile=/tmp/oai_cleanup_known_hosts -o StrictHostKeyChecking=accept-new' \
MONO_HOST=serber@10.76.170.38 \
CU_HOST=serber@10.76.170.38 \
DU_HOST=serber@10.76.170.40 \
PI_HOST=serber@10.76.170.18 \
./scripts/oai-lab-tui --verify
```

Observed result:

- `serber-firecell`: detected as `serber-firecell`
- `serber-minipc`: detected as `serber-minipc (enp2s0 10.76.170.40)`

No full radio scenario was started as part of this cleanup pass.

## Next Actions

1. Fix the local SSH alias for `serber-firecell` so it no longer resolves to
   the MiniPC Wi-Fi address.
2. Run the desired TUI scenario validation, especially Ethernet rollback.
3. If validation passes and no quarantined path is needed, delete the dated
   quarantine directories to actually free disk space.
4. Use elevated permissions only for the two remaining `/tmp/gre-debug-*.pcap`
   files if they are confirmed unnecessary and sanitized evidence has already
   been recorded.

## Follow-Up Deletion Pass

After the operator requested deletion of non-essential files while preserving
the quarantine directories, a second pass removed the remaining explicit
non-essential files outside `_cleanup_quarantine`.

Deleted outside quarantine:

- stale Xorg/GVFS/Firefox crash logs;
- stale top-level OAI stats logs;
- old TUI, CU, DU, ping, seed, Ethernet, Quectel, and GRE debug logs outside
  quarantine;
- stale `/tmp/gre-debug-*.pcap` files where permission allowed;
- the duplicate non-essential `/home/serber/monolithic` tree on
  `serber-minipc`;
- old `known_hosts.old` files on DU hosts;
- stale `.tar.gz` file from MiniPC trash.

Preserved:

- all `/home/serber/_cleanup_quarantine/20260629/` directories;
- active TUI/Core/CU/DU source/config paths;
- active `/tmp/oai-firecell-donor-monolithic.log`, because
  `serber-firecell` was running donor `nr-softmodem` processes using the
  donor runtime config.

Post-deletion check:

- `./scripts/oai-lab-tui --verify` passed with direct IP overrides.
- Outside quarantine, the only remaining cleanup-pattern match was the active
  `/tmp/oai-firecell-donor-monolithic.log` on `serber-firecell`.

## Home Directory Directory Cleanup

After the operator clarified that the goal was a visibly clean home directory,
a third pass removed non-essential top-level directories while preserving:

- all `/home/serber/_cleanup_quarantine/20260629/` directories;
- active TUI/Core/CU/DU paths;
- SSH and minimal hidden user configuration directories.

Removed outside quarantine:

- standard empty user folders such as `Desktop`, `Documents`, `Downloads`,
  `Music`, `Pictures`, `Public`, `Templates`, `Videos`, and localized Pi
  equivalents;
- `.cache`, `.mozilla`, `.anydesk`, and `snap` where they were not needed by
  the TUI;
- duplicate or historical non-TUI source trees:
  - `serber-firecell`: `/home/serber/cu-du`
  - `serber-minipc`: `/home/serber/cu-du-backhaul`

Final top-level home contents:

`serber-firecell`:

```text
.config
.gnupg
.local
.ssh
_cleanup_quarantine
cu-du-minipc
cu-du-minipc-backhaul
docker
monolithic
```

`serber-minipc`:

```text
.config
.gnupg
.gnuradio
.local
.ssh
_cleanup_quarantine
cu-du
```

`serber-pi`:

```text
.config
.local
.ssh
_cleanup_quarantine
cu-du
```

Post-directory-cleanup validation:

- `./scripts/oai-lab-tui --verify` passed with direct IP overrides.
- `serber-firecell` still had the active donor `nr-softmodem` process running.
- Root filesystem usage after cleanup:
  - `serber-firecell`: about `36%`
  - `serber-minipc`: about `7%`
  - `serber-pi`: about `82%`

## Markdown, Diff, and Package File Cleanup

After the operator requested removal of non-essential `.deb`, `.md`, and
`.diff` files from the home directories, a fourth pass removed those file types
outside `_cleanup_quarantine`.

Deleted outside quarantine:

- `serber-firecell`: 213 matching files
- `serber-minipc`: 11 matching files
- `serber-pi`: 153 matching files

Final check:

- Remaining `.deb`, `.md`, `.diff` files outside quarantine: `0` on all three
  hosts.
- `./scripts/oai-lab-tui --verify` passed with direct IP overrides.
