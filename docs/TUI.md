# TUI

Run from the repository root:

```bash
./scripts/oai-lab-tui
```

The TUI is a safe guide for newcomers. It covers:
- monolithic OAI reference;
- Ethernet CU/DU with SIB8 rollback;
- Wi-Fi GRE CU/DU backhaul;
- Quectel/WireGuard F1 target;
- Raspberry Pi DU future work;
- config templates, patch notes, experiment reports, and repo checks.

It does not SSH, deploy, rewrite history, or run live hardware tests. It creates only local generated runbooks under `conf/generated/` and experiment reports under `experiments/`.

Useful commands:

```bash
./scripts/oai-lab-tui --self-test
./scripts/oai-lab-tui --dashboard
./scripts/oai-lab-tui --write-runbook ethernet
./scripts/oai-lab-tui --make-experiment quectel-independent-donor
```
