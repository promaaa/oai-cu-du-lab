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

Validated scope:
- CU-to-DU `WRITE-REPLACE WARNING REQUEST`.
- One SIB8 segment with `mode = 0` and `dataCodingScheme = 48`.
- Commercial-handset display inside the lab's Faraday-cage setup.

Not yet validated or claimed:
- `WRITE-REPLACE WARNING RESPONSE` and Notification Information handling.
- PWS Cancel, restart/failure indications, deduplication, and multi-segment
  delivery through F1.
- Modes `1` and `2`, or data-coding values other than the tested `48`.

Use:
- Apply only to an external OAI source tree pinned to the expected commit.
- Keep runtime `sib8.conf` values non-secret and outside this repository.
- Start from the test-only public profile in `conf/pws-sib8.example`; changing
  an identifier, coding scheme, mode, or text requires fresh acceptance gates.
- Record apply/build/runtime evidence in an experiment report.
