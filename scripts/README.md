# Scripts

This directory intentionally stays small.

## Operator TUI

Run the lab launcher from the repository root:

```bash
./scripts/oai-lab-tui
```

Create the ignored machine profile first:

```bash
./scripts/oai-lab-tui --init-local-config
```

Useful non-interactive commands:

```bash
./scripts/oai-lab-tui --dashboard
./scripts/oai-lab-tui --self-test
./scripts/oai-lab-tui --dry-run --action status
./scripts/oai-lab-tui --dry-run --action start-monolithic
./scripts/oai-lab-tui --dry-run --action start-ethernet
./scripts/oai-lab-tui --action quectel-preflight
./scripts/oai-lab-tui --make-experiment quectel-independent-donor
```

The launcher is allowed to SSH and run the deployed lab modes. Keep it:

- parameterized by `conf/local/lab.env` and environment variables;
- free of passwords, subscriber values, generated configs, raw logs, and private keys;
- dry-run friendly for launch commands;
- explicit about stop/rollback behavior and safety gates.

Do not migrate old one-command deployment scripts unless they are rewritten to be:
- parameterized by environment variables or template files;
- free of passwords, subscriber values, generated configs, raw logs, and host-specific assumptions;
- dry-run friendly where practical;
- paired with rollback and sanitized evidence collection.

Prefer the operator TUI for repeated lab actions and the templates in `conf/templates/` for config changes.
