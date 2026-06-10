# Performance

Patch:
- `oai-dl-mcs-debug-instrumentation.patch`

Expected OAI base:
- `102965a669b9444857c27843ec8ce62780bf9d37`

Scope:
- Temporary `MCSDBG` scheduler instrumentation for the split-mode DL MCS
  investigation.
- Logs UE RNTI, BLER state, `num_dl_sched`, HARQ retransmission window,
  `dl_max_mcs`, selected MCS, buffer state, and CQI/SINR-derived cap updates.

Use:
- Apply only to an external OAI source tree pinned to the expected commit.
- Build and run first on the split DU, where DL scheduling is owned in CU/DU
  split mode.
- Keep raw OAI logs out of Git. Commit only sanitized `MCSDBG` excerpts and
  measurement summaries in an experiment report.
- Remove or revert this patch before preserving a rollback baseline build.

Keep future additions focused on reproducible measurement, not broad logs. A useful performance artifact should define:
- baseline being compared;
- pinned repository and OAI commits;
- exact measurement method;
- sanitized evidence;
- rollback impact.
