# Public artifact manifest

Last reconciled: 2026-08-13.

## External source pin

- OpenAirInterface commit:
  `102965a669b9444857c27843ec8ce62780bf9d37`

## Required public contract

| Path | Role |
|---|---|
| `docs/STATUS.md` | current capability and evidence status |
| `docs/BASELINES.md` | accepted values, rollback baseline, and causal limits |
| `docs/NETWORK.md` | topology and transport roles |
| `docs/SECURITY.md` | secret and publication policy |
| `docs/evidence/PWS-F1.md` | sanitized proof for PWS/SIB8 over F1 |
| `docs/evidence/BENCHMARKS.md` | reconciled throughput chronology |
| `docs/evidence/RESOURCE_PROFILE.md` | sanitized compute, thermal, and power-bound evidence |
| `docs/prompts/PWS_REPOSITORY_STRENGTHENING.md` | agent prompt for the next standards-scoped PWS increment |
| `conf/pws-sib8.example` | safe, test-only PWS values used by the single-segment record |
| `patches/sib8/` | PWS/SIB8-over-F1 implementation |
| `patches/performance/` | scheduler instrumentation and transport notes |
| `patches/rpi-du/` | Raspberry Pi/B210 host-specific modification |
| `docs/PDFs/research-paper.tex` | WCNC Track 4 manuscript source |
| `docs/PDFs/research-paper.bib` | manuscript bibliography |
| `docs/PDFs/research-paper.pdf` | verified six-page submission PDF |

## Patch identities

| Patch | SHA-256 |
|---|---|
| `patches/sib8/oai-pws-sib8-cu-du.patch` | `e4b820e87f21916274e0581477527804b56e669738d20a9ced593b4eb6292545` |
| `patches/performance/oai-dl-mcs-debug-instrumentation.patch` | `17059f71e4a06ebe5fa29b616436ec9d4d01ef773073fcbd82f1bbcac6f05be3` |
| `patches/rpi-du/oai-b210-106prb-61p44msps.patch` | `67e9a432a678bffed6c412d32f310bca3e1fb4fdad5b73e45bc1230d6525c5b8` |

Submission PDF SHA-256:
`a2fb67db6e0317627f63b68de2e6fbd3b1f798b05416abd2918718d118014529`.

Verify a patch before use with `shasum -a 256 <patch>`, then apply it only to
an external checkout at the pinned OAI commit. Generated configurations, raw
logs, captures, and subscriber material are not artifact inputs.

## Historical PWS provenance

Three older repositories were inspected because they preserve the development
chronology. Their safe PWS facts are minimized and pinned in
`docs/evidence/PWS-F1.md`. They are not artifact dependencies and are not cited
by the paper because their history includes revoked operational material.

All three preserved the same six-field test file, with SHA-256
`92fe6de0a573ac930d8e2054042d22dc33fbd87572b33c2b8ca655f606b5febd`.
The canonical, reviewed replacement is `conf/pws-sib8.example`.
