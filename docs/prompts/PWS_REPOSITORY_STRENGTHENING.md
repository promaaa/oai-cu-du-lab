# Agent prompt: strengthen the canonical PWS-over-F1 artifact

Copy the prompt below into the implementation agent. The selected repository
is `promaaa/oai-cu-du-lab`; the three historical PWS repositories are
provenance-only and must not be modified or used as runtime inputs.

---

You are strengthening the PWS/SIB8-over-F1 research artifact in the canonical
repository `promaaa/oai-cu-du-lab`.

Read `AGENTS.md`, `README.md`, `docs/STATUS.md`, `docs/BASELINES.md`,
`docs/NETWORK.md`, `docs/SECURITY.md`, `docs/REPRODUCIBILITY.md`,
`docs/ARTIFACT_MANIFEST.md`, and `docs/evidence/PWS-F1.md` before changing
anything.

Objective: extend the currently validated single-segment CU-to-DU
Write-Replace Warning request path with the smallest standards-scoped,
reproducible improvement that can be proven end to end. Prioritize the F1AP
Write-Replace Warning Response. If the pinned OAI interfaces make that
increment infeasible, document the exact blocker and implement the next
smallest testable improvement, such as deterministic update/replacement or
cancel handling. Do not claim multi-segment or complete PWS support unless it
is actually validated.

Non-negotiable constraints:

1. Keep OpenAirInterface external and pinned to
   `102965a669b9444857c27843ec8ce62780bf9d37` unless a pin change is separately
   justified, tested, and documented.
2. Store every OAI modification as a feature-separated patch under
   `patches/sib8/`; never vendor an OAI source tree.
3. Preserve the MiniPC Ethernet CU/DU + SIB8 rollback baseline.
4. Use only the isolated test PLMN, test-only warning text, Faraday-cage RF
   boundary, intended access UE, and exclusive lab ownership.
5. Never commit credentials, subscriber values, private keys, generated
   configs, raw logs, packet captures, handset screenshots with identifiers,
   or historical operational material.
6. Do not copy files from `promaaa/cu-du`, `promaaa/cu-du-backhauling`, or
   `promaaa/cu-du-5g-backhauling`. Their pinned safe facts are already reduced
   in `docs/evidence/PWS-F1.md`.
7. Do not claim success from F1 setup or an RF-ready marker alone.

Required implementation workflow:

1. Map the selected 3GPP TS 38.473 procedure to the pinned OAI call path and
   state the exact implemented and unimplemented information elements.
2. Make the smallest source change in an external pinned OAI checkout.
3. Export the change as a new or updated patch under `patches/sib8/`, compute
   its SHA-256, and update `docs/ARTIFACT_MANIFEST.md`.
4. Add deterministic static tests for handler registration, allocation and
   ownership, encoding/decoding, error paths, and regression of the existing
   request path.
5. Run `git apply --check` against a clean checkout of the pinned OAI commit.
6. Execute the Ethernet baseline first, then at most one wireless F1 bearer.
7. Record a sanitized ordered chain: CU construction, F1AP request, DU decode,
   SIB8 installation/scheduling, intended-handset observation, the new response
   or control behavior, user-plane health, clean stop, and Ethernet rollback.
8. Update `docs/evidence/PWS-F1.md`, the applicable patch README, status, and
   rollback instructions. Explicitly list every standards feature still out of
   scope.
9. Scan the staged tree and complete reachable Git history for secrets and raw
   evidence before publishing.

Acceptance criteria:

- The patch applies cleanly to the pinned OAI revision.
- Existing single-segment PWS delivery still reaches the intended commercial
  UE inside the RF containment boundary.
- The new behavior is visible at both relevant protocol endpoints and is
  represented by sanitized, non-identifying evidence.
- Registration, PDU session, Internet/data service, clean stop, and Ethernet
  rollback pass after the PWS action.
- The public artifact makes no broader standards claim than the evidence.

If physical lab access is unavailable, complete only source analysis, patch,
static tests, apply checks, and a precise pending-validation plan. Mark runtime
validation as pending; never convert an unexecuted test into a PASS.

---
