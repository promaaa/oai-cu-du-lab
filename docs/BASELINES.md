# Baselines

## Monolithic OAI Reference

- Status: working reference only.
- Observed user throughput: about `40 Mb/s`.
- Evidence: `kaust-5g-research` progress reports describe monolithic validation and OAI PC checks; the user supplied this throughput as confirmed.
- OAI commit: not confirmed from repository evidence for this exact baseline.

## Ethernet CU/DU With SIB8

- Status: working canonical rollback baseline.
- Observed user throughput: about `19-23 Mb/s`.
- Evidence: `cu-du/README.md` documents working CU/DU split and PWS/SIB8 over split; `cu-du/docs/PWS_SIB8_CU_DU_DEPLOYMENT.md` records phone PWS reception and data working with `oai` APN/DNN; `cu-du-backhauling/BACKHAULING.md` records Ethernet throughput evidence.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37` is supported by `cu-du/conf/env.sh`, `cu-du/README.md`, and PWS deployment docs.
- Rollback baseline: yes.

## Wi-Fi CU/DU With SIB8

- Status: working wireless-backhaul baseline candidate.
- Observed user throughput: about `12 Mb/s`.
- Evidence: `cu-du-backhauling/README.md` and `BACKHAULING.md` document Wi-Fi GRE F1 migration, UE registration, low BLER, and rollback to Ethernet. `kaust-5g-research` progress reports also describe PWS/SIB8 validation with Wi-Fi backhaul.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37` is supported by `cu-du-backhauling/conf/env.sh` and deployment scripts.
- Rollback baseline: no, but documented as confirmed working.

## Quectel F1 Backhaul

- Status: not a verified stable baseline.
- Evidence: `cu-du-5g-backhauling/README.md` and `docs/quectel-f1-backhaul.md` show modem detection, OAI cell lock, QMI data, WireGuard path, partial F1 packet steering, and circular-dependency failure for same-cell full F1.
- OAI commit: `102965a669b9444857c27843ec8ce62780bf9d37` is supported by `cu-du-5g-backhauling/conf/env.sh`.
