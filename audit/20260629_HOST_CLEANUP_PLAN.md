# Host Cleanup Plan - serber-firecell, serber-minipc, serber-pi

Date: 2026-06-29

This plan is for making the three lab hosts clearer while preserving every
configuration needed by the TUI. It is intentionally evidence-gated: inventory
first, quarantine second, deletion only after TUI validation and rollback proof.

## Scope

Hosts:

- `serber-firecell`: 5GC, CU, monolithic reference, and firecell donor gNB.
- `serber-minipc`: access DU, radio/backhaul migration evidence, and caged
  Quectel workflow while it remains the validated modem path.
- `serber-pi`: lightweight DU benchmark target for Ethernet, Wi-Fi GRE, and
  Quectel/WireGuard profiles.

Do not clean `oai-pc` in this pass; it is historical and unverified in the
current TUI flow.

## Non-Negotiable Guardrails

- Do not delete anything before the host inventory has been captured.
- Do not move paths referenced by `conf/local/lab.env`, `conf/lab.env.example`,
  `scripts/oai-lab-tui`, or the current TUI runbooks.
- Do not commit or copy raw logs, packet captures, subscriber material,
  passwords, private keys, or unsanitized `.env` files.
- Keep the Ethernet CU/DU with SIB8 as the rollback baseline.
- Keep historical names such as `cu-du-minipc` or `oai-cn5g-minipc-*` when they
  are still real deployment paths, even if the operator-facing wording now uses
  Pi/access-DU language.
- Treat `serber-minipc` management IPs as drift-prone; rediscover live reachability
  before changing remote files.

## Phase 0 - Current Local Status

Initial checks from this workstation:

- `node --check scripts/oai-lab-tui`: passed.
- `./scripts/oai-lab-tui --verify`: did not complete because SSH to
  `serber-firecell` timed out, then minipc discovery failed.
- Direct SSH attempts to `serber@10.76.170.38`, `serber-minipc`, and
  `serber-pi` timed out from this session.
- Read-only inventory attempt:
  `experiments/20260629_104253_host_cleanup_inventory/`. All three host
  attempts failed at SSH reachability from this workstation.
- Corrected live SSH targets supplied by the operator and verified afterward:
  `serber@10.76.170.38` is `serber-firecell`, `serber@10.76.170.40` is
  `serber-minipc`, and `serber@10.76.170.18` is `serber-pi`.
- Local SSH alias warning: in this workstation session, `serber-firecell`
  resolves to `10.85.168.144`, which identified as `serber-minipc`. Use the
  direct firecell IP for cleanup until the local SSH config is fixed.

The reachability issue was resolved for this cleanup by using direct host IPs
and a temporary known-hosts file in `/tmp/oai_cleanup_known_hosts`.

Post-cleanup inventory:

- `experiments/20260629_105254_host_cleanup_inventory/`

TUI reachability validation after quarantine passed with direct SSH overrides:

```bash
LAB_SSH_OPTS='-o BatchMode=yes -o ConnectTimeout=8 -o UserKnownHostsFile=/tmp/oai_cleanup_known_hosts -o StrictHostKeyChecking=accept-new' \
MONO_HOST=serber@10.76.170.38 \
CU_HOST=serber@10.76.170.38 \
DU_HOST=serber@10.76.170.40 \
PI_HOST=serber@10.76.170.18 \
./scripts/oai-lab-tui --verify
```

Observed result: `serber-firecell` and `serber-minipc (enp2s0 10.76.170.40)`
were detected successfully.

## Phase 1 - Read-Only Inventory

Run:

```bash
./scripts/collect-host-cleanup-inventory.sh
```

If aliases are unavailable, pass explicit targets:

```bash
./scripts/collect-host-cleanup-inventory.sh \
  serber@10.76.170.38 \
  serber@10.76.170.40 \
  serber@10.76.170.18
```

The script writes ignored local evidence under:

```text
experiments/YYYYMMDD_HHMMSS_host_cleanup_inventory/
```

It captures only filenames, sizes, process summaries, Docker summaries, disk
usage, and candidate cleanup paths. It does not read file contents.

## Phase 2 - Keep List

These paths are protected unless a later TUI change removes their references.

### serber-firecell

- `/home/serber/monolithic/oai-cn5g`
- `/home/serber/monolithic/openairinterface5g`
- `/home/serber/cu-du-minipc/oai-cn5g-minipc`
- `/home/serber/cu-du-minipc-backhaul/source/openairinterface5g`
- the active monolithic gNB config, CU configs, donor config, and `sib8.conf`
  files referenced by `conf/local/lab.env`

### serber-minipc

- `/home/serber/cu-du/source/openairinterface5g`
- active DU configs referenced by the TUI
- Quectel/WireGuard local state required by the caged Quectel workflow
- sanitized rollback and migration evidence that is still referenced by docs

### serber-pi

- the active OAI DU tree used for Pi Ethernet/Wi-Fi/Quectel benchmarks
- Pi DU configs such as `gnb-pi.conf` and generated runtime config inputs
- local scripts needed for selected F1 transport setup
- Pi hardware validation notes for B210 visibility, throttling, CPU/RAM, and
  temperature

## Phase 3 - Quarantine, Not Delete

Create on each host:

```bash
mkdir -p /home/serber/_cleanup_quarantine/20260629
```

Move only items that meet all of these tests:

- not referenced by the TUI, env files, runbooks, or current evidence;
- not an active OAI source tree;
- not a secret-bearing file that needs secure handling instead;
- not needed for Ethernet rollback;
- older than the current active run window.

Good quarantine candidates:

- old experiment folders not linked from current docs;
- duplicate OAI clones with no current process/config reference;
- `.bak`, `.old`, `.orig`, tarballs, zip files, and local scratch folders;
- stale runtime configs under `/tmp` after all OAI processes are stopped;
- raw logs and pcaps that are no longer needed locally, handled outside Git.

Avoid broad commands such as:

```bash
docker system prune -a
rm -rf /home/serber/cu-du*
rm -rf /tmp/oai-*
```

Those are too coarse for this lab.

## Phase 4 - Host Order

1. `serber-pi`: clean first because its desired role is narrow.
2. `serber-minipc`: clean second; preserve rollback and Quectel evidence.
3. `serber-firecell`: clean last because it owns Core/CU/donor state.

## Phase 5 - Validation Gates

After each host cleanup:

```bash
node --check scripts/oai-lab-tui
./scripts/oai-lab-tui --verify
```

Then validate the relevant mode:

- after `serber-pi`: Pi Ethernet benchmark at minimum;
- after `serber-minipc`: Ethernet CU/DU rollback and caged Quectel guard;
- after `serber-firecell`: monolithic reference and Ethernet CU/DU rollback.

The cleanup is not done until Ethernet rollback is rechecked after all host
changes.

## Final Evidence To Record

Create a follow-up note after the cleanup with:

- pre-clean inventory path;
- quarantine path per host;
- exact paths moved or removed;
- TUI validation output summary;
- rollback baseline evidence;
- remaining paths intentionally kept even if their names look historical.
