# Sanitized PWS/SIB8 over F1 evidence record

Record ID: `PWS-F1-GRE-2026-05-19`

Status: accepted end-to-end execution record for the tested single-segment
CU-to-DU request path.

## Reproducible inputs

- OAI base commit: `102965a669b9444857c27843ec8ce62780bf9d37`
- Feature patch: `patches/sib8/oai-pws-sib8-cu-du.patch`
- Patch SHA-256: `e4b820e87f21916274e0581477527804b56e669738d20a9ced593b4eb6292545`
- Architecture: split CU/DU with F1-C over SCTP and a B210 access radio
- UE: commercial handset; subscriber identifiers are deliberately omitted
- Tested warning profile: one SIB8 segment, `mode = 0`, UCS-2 branch
  (`dataCodingScheme = 48`), test-only text
- RF boundary: the B210 access cell and intended handset were operated inside
  the lab's Faraday-cage setup; the donor/backhaul radio remained a separate
  cell where applicable

## Sanitized event chain

The retained raw run material was reduced to the following ordered gates. Host,
radio, cell, subscriber, and warning-content identifiers were removed before
publication.

| Order | Observation | Gate |
|---:|---|---|
| 1 | CU and DU reported a live F1 association | PASS |
| 2 | CU RRC built the SIB8 warning and issued the F1AP Write-Replace Warning procedure | PASS |
| 3 | F1-C capture contained the Write-Replace Warning request on the selected F1 bearer | PASS |
| 4 | DU decoded the warning container and installed SIB8 in other-system-information scheduling | PASS |
| 5 | DU scheduled the corresponding BCCH-DL-SCH payload on the B210 access cell | PASS |
| 6 | The intended commercial UE remained attached to that access cell | PASS |
| 7 | The handset displayed the transmitted public-warning alert | PASS |
| 8 | The scenario stopped cleanly and the Ethernet CU/DU rollback remained available | PASS |

This event chain distinguishes implementation evidence from UE-visible
execution evidence. F1 setup alone is not counted as proof of PWS delivery.

## Sanitized log fingerprints

The historical deployment record retained the following non-identifying
markers. They are sufficient to match each software boundary without exposing
raw logs or subscriber state:

| Boundary | Sanitized marker |
|---|---|
| CU/F1 association | `CU_handle_F1_SETUP_REQUEST` |
| CU SIB8 build | `[SIB8] ... number of segments:1` |
| CU F1 dispatch | `CU Task Received F1AP_WRITE_REPLACE_WARNING` |
| DU F1 decode | `DU_handle_WriteReplaceWarning: sib_type=8` |
| DU MAC install | `Configured PWS/SIB8 SI segment 0` |
| DU RF state | `RU 0 RF started` |
| UE observation | Intended handset displayed the test warning |

## Patch-to-observation map

| Patch scope | Public observation |
|---|---|
| CU SIB8 construction and F1AP dispatch | Gates 2 and 3 |
| DU F1AP Write-Replace Warning handler | Gates 3 and 4 |
| DU MAC SIB8 installation and scheduling | Gates 4 and 5 |
| End-to-end radio delivery | Gates 6 and 7 |

## Tested configuration and possible values

All three historical repositories used the same test configuration. The exact
legacy file has SHA-256
`92fe6de0a573ac930d8e2054042d22dc33fbd87572b33c2b8ca655f606b5febd`.
The canonical safe copy is `conf/pws-sib8.example`.

| Field | Tested value | Values supported or evidenced by this patch |
|---|---|---|
| `messageIdentifier` | `1112` | Four hexadecimal digits; only `1112` has end-to-end evidence |
| `serialNumber` | `FF00` | Four hexadecimal digits; only `FF00` has end-to-end evidence |
| `dataCodingScheme` | `48` | Code paths exist for `01` (GSM 7-bit) and `48` (UCS-2); only `48` is end-to-end validated |
| `warningType` | `0000` | Retained for legacy file compatibility; the released patch does not consume it |
| `text` | `Hello this is a test warning message.` | Test-only text; a short single-segment message is the validated scope |
| `mode` | `0` | Modes `1` and `2` exist in the builder but are not validated; use `0` for the released record |

Do not substitute an operational emergency identifier or warning. A new value
creates a new experiment and requires fresh CU, F1, DU, RF, and handset gates.

## Historical provenance

The following pinned, safe files corroborate the configuration lineage and
phone-side outcome. They are historical context only, not runtime dependencies
or substitutes for this canonical record:

| Source | Pinned revision | Sanitized fact imported |
|---|---|---|
| [`promaaa/cu-du-backhauling/sib8.conf`](https://github.com/promaaa/cu-du-backhauling/blob/742f599a980cc557239d7a15caa07adee1f25cb0/sib8.conf) | `742f599a980cc557239d7a15caa07adee1f25cb0` | Same six-field test profile and digest |
| [`promaaa/cu-du/docs/PWS_SIB8_CU_DU_DEPLOYMENT.md`](https://github.com/promaaa/cu-du/blob/e419ff5f8a1291a51b7a56ebb0b933e67db400d3/docs/PWS_SIB8_CU_DU_DEPLOYMENT.md) | `e419ff5f8a1291a51b7a56ebb0b933e67db400d3` | OAI pin, CU/DU log markers, single segment, handset warning, registration, and data outcome |
| [`promaaa/cu-du-5g-backhauling/README.md`](https://github.com/promaaa/cu-du-5g-backhauling/blob/11050ab74514a8ad26a3c9c62c53b0566a71b51e/README.md) | `11050ab74514a8ad26a3c9c62c53b0566a71b51e` | Earlier Quectel/WireGuard F1 gate with PWS, access-cell registration, and handset Internet |

The legacy Quectel record reported about 5.5 Mb/s and is retained only as an
early functional milestone. It is not the final 76.7 Mb/s x86 or 68.4 Mb/s Jetson
benchmark reported in `docs/evidence/BENCHMARKS.md`.

The historical repositories are not cited by the paper and must not be cloned
as artifact inputs: their old history contains operational material that was
subsequently revoked. Only the sanitized facts above are imported.

## Standards scope

The released patch and this record validate the CU-to-DU
`WRITE-REPLACE WARNING REQUEST` path and a single SIB8 segment through handset
display. They do not claim a complete TS 38.473 warning-service implementation.
The `WRITE-REPLACE WARNING RESPONSE`, Notification Information-based
deduplication, PWS Cancel, restart/failure indications, and end-to-end
multi-segment delivery remain outside the validated scope.

## RF and alert-safety boundary

- The intended access UE and B210 access radio operate inside the Faraday-cage
  setup used by the lab.
- Warning text is explicitly test-only and is sent on the isolated lab PLMN.
- The donor cell used for Quectel backhaul is distinct from the access cell;
  donor attachment is not accepted as access-UE evidence.
- A run must stop if the access UE, RF containment, selected radio, or exclusive
  lab ownership cannot be proven.
- No production alert identifier, subscriber credential, or unredacted handset
  notification is published.

## Evidence handling

Raw logs and packet captures remain outside Git because they can contain
subscriber and infrastructure identifiers. The public record retains the OAI
pin, patch digest, ordered acceptance gates, bearer role, and rollback outcome.
No secret, raw packet capture, unredacted log, or subscriber identifier is
required to reproduce the code path.
