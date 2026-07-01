# Raspberry Pi DU

## B210 106 PRB support

`oai-b210-106prb-61p44msps.patch` adds the missing B200/B210
`61.44e6` sample-rate case used by Raspberry Pi DU `106 PRB`
configurations when the softmodem is started without `-E`. Without it, the DU
accepts F1 setup and then exits with:

```text
[HW] Error: unknown sampling rate 61440000.000000
```

The strongest current Pi TUI evidence starts the DU with `-E`, matching the
older working Pi shape. In that mode OAI runs the 106 PRB B210 cell at 46.08
MSps. Keep the patch applied anyway so direct/manual starts without `-E` fail
less surprisingly.

Retained facts:
- Raspberry Pi 5 DU work exists in older research notes.
- Pi 5 evidence should be treated as partial until revalidated against the canonical baseline.

Future migration should focus on compact config templates, build constraints, and one validated experiment report.
