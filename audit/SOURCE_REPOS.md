# Source Repository Audit

## `cu-du`

- Local path: `/Users/promaa/Documents/cu-du`
- Remote: `https://github.com/promaaa/cu-du.git`
- Apparent purpose: current CU/DU split deployment with SIB8/PWS support.
- Useful material: PWS/SIB8 architecture notes, patch application flow, host roles, OAI commit evidence, generated-config patterns, rollback baseline context.
- Observed freshness/status: active local branch has user modifications; remote `origin/main` points at `Document PWS deployment layout`.
- Working deployment evidence: yes, documents phone PWS reception and data working with `oai` APN/DNN.
- Later migration candidates: SIB8 patch, config templates, deployment helpers, validation helpers.
- Ignore or sanitize: subscriber material, password-based SSH helpers, generated OAI source/config output, raw runtime paths.

## `cu-du-5g-backhauling`

- Local path: `/Users/promaa/Documents/cu-du-5g-backhauling`
- Remote: `https://github.com/promaaa/cu-du-5g-backhauling`
- Apparent purpose: Quectel modem based F1 backhaul work for the CU/DU split.
- Useful material: Quectel RM500Q-GL inventory, WireGuard topology, partial F1-over-Quectel evidence, circular-dependency analysis, future independent-donor direction.
- Observed freshness/status: clean local clone on `feature/quectel-f1-backhaul`, commit `202fa56`.
- Working deployment evidence: partial only. Modem detection, cell lock, packet data, WireGuard path, and packet steering are evidenced; stable full F1 is not validated.
- Later migration candidates: Quectel detection/connectivity scripts, WireGuard templates, validation capture scripts, rollback logic.
- Ignore or sanitize: any private keys, password helpers, IMSI/ICCID details, generated configs, tcpdump/raw logs.

## `cu-du-backhauling`

- Local path: `/Users/promaa/Documents/cu-du-backhauling`
- Remote: `https://github.com/promaaa/cu-du-backhauling.git`
- Apparent purpose: earlier wireless-backhaul experiments using Wi-Fi GRE for F1 transport.
- Useful material: Wi-Fi GRE topology, policy-routing approach, throughput/latency comparison, rollback procedure.
- Observed freshness/status: local working tree has user modifications on `feature/quectel-f1-backhaul`; `origin/main` is Wi-Fi GRE work.
- Working deployment evidence: yes, documents F1 migration over Wi-Fi GRE, UE registration, low BLER, and throughput.
- Later migration candidates: GRE setup/teardown logic, config-generation patterns, validation checklist.
- Ignore or sanitize: subscriber material, password helpers, generated configs, raw logs.

## `kaust-5g-research`

- Local path: `/Users/promaa/Documents/kaust-5G-research`
- Remote: `https://github.com/promaaa/kaust-5G-research.git`
- Apparent purpose: broad internship/research documentation.
- Useful material: monolithic reference context, older Pi DU research, broader drone/portable-DU direction, presentation-level performance summaries.
- Observed freshness/status: local working tree has user modifications; repo includes broad notes and vendored/generated material.
- Working deployment evidence: yes for historical monolithic, Pi, PWS, and research-progress milestones, but facts conflict with newer repos in places.
- Later migration candidates: concise historical baseline facts only.
- Ignore or sanitize: broad literature notes, presentations, vendored dependencies, old credentials, old subscriber details, obsolete network facts.
