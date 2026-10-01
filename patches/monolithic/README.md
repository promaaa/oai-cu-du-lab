# Monolithic gNB patches

Moved from the former `monolithic` repository (now archived).

| Patch | What it adds | OpenAirInterface base commit |
|---|---|---|
| `oai-warning.patch` | SIB8 warning transmission from a monolithic gNB: SIB8 built in RRC, segmented transmission over several System Information messages, GSM 7-bit and UCS2 coding, runtime parameter updates | `102965a669b9444857c27843ec8ce62780bf9d37` |
| `cross-cell.patch` | UE-side cross-cell verification of received SIB8 warnings: scans neighbouring cells, compares warning contents, then returns to the original carrier | `bf325466b38cb7c2560a8fc86de799bfc6799167` |

For the split CU/DU version of the warning path, see [`../sib8/`](../sib8/).
