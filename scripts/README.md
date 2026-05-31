# Scripts

This directory intentionally stays small.

## TUI

Run the guided lab interface from the repository root:

```bash
./scripts/oai-lab-tui
```

Useful non-interactive commands:

```bash
./scripts/oai-lab-tui --dashboard
./scripts/oai-lab-tui --self-test
./scripts/oai-lab-tui --make-experiment quectel-independent-donor
./scripts/oai-lab-tui --write-runbook monolithic
./scripts/oai-lab-tui --write-runbook ethernet
```

Do not migrate old one-command deployment scripts unless they are rewritten to be:
- parameterized by environment variables or template files;
- free of passwords, subscriber values, generated configs, raw logs, and host-specific assumptions;
- dry-run friendly where practical;
- paired with rollback and sanitized evidence collection.

For now, prefer the templates in `conf/templates/` and the runbook in `docs/RUNBOOK.md`.
