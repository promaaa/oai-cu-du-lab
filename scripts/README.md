# Scripts

This directory intentionally stays small.

Do not migrate old one-command deployment scripts unless they are rewritten to be:
- parameterized by environment variables or template files;
- free of passwords, subscriber values, generated configs, raw logs, and host-specific assumptions;
- dry-run friendly where practical;
- paired with rollback and sanitized evidence collection.

For now, prefer the templates in `conf/templates/` and the runbook in `docs/RUNBOOK.md`.
