# Backlog

Known items to fix in later changes. A finding that a change does not fix, because it is outside the change's scope or below the confidence the contributor agent acts on, is recorded here with where it is in the code, why it matters, and how to fix it, so that it is not lost and the next change can start from it. Each item is removed by the change that fixes it, through the OpenSpec loop like any other change.

## make types leaves build/carat.rbs that a later spin build warns about

- Where: the `types` target in the `Makefile` writes `build/carat.rbs` with `--emit-rbs`, inside the tree `spin` scans.
- Why it matters: `spinel_rbs_extract` reports a parse failure on the emitted file at every later `spin build`, `spin test`, and `make snapshots`, because of a doubled namespace separator in the class names it writes; the noise hides real warnings and the file has to be deleted by hand. Observed during the Struct change and again during the command grammar change.
- Fix outline: have the `types` target write the file outside the `spin` source tree, or delete it after printing.
