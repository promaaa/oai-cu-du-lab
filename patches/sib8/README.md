# SIB8/PWS Patch

Patch:
- `oai-pws-sib8-cu-du.patch`

Source:
- Migrated from `/Users/promaa/Documents/cu-du/patches/oai-pws-sib8-cu-du.patch`.
- SHA-256 after whitespace normalization: `e4b820e87f21916274e0581477527804b56e669738d20a9ced593b4eb6292545`.

Expected OAI base:
- `102965a669b9444857c27843ec8ce62780bf9d37`

Scope:
- CU-side SIB8 warning construction and F1AP dispatch.
- F1AP WriteReplaceWarning encode/decode path.
- DU-side MAC/SIB scheduling for SIB8 system information.
- Scheduler fixes needed for other-SI allocation.

Use:
- Apply only to an external OAI source tree pinned to the expected commit.
- Keep `sib8.conf` values non-secret and use `conf/templates/sib8.conf.template` as the starting point.
- Record apply/build/runtime evidence in an experiment report.
