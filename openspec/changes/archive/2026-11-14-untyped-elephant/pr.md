test: read table rows through typed readers

## Summary

Reads test table rows and array-input table blocks through typed element readers, so the test runner no longer calls `[]` on receivers Spinel types untyped. From Spinel 2440954d1 on, each such call makes code generation rebuild the load record by walking the whole program, which took the runner from 39 rebuilds to 4,501 and kept `SPINEL_REF` pinned at 6af548c9; this first part removes the main cause, the table rows, bringing the runner at 6b43fe94 to 1,181 rebuilds.

---

## Changes

- Change `Carat::Testing#table` to read each row through a private typed reader, `cell`, so its body makes no untyped `[]` call.
- Add `Carat::Testing#cases`, a table whose every input is an array literal, yielding the input typed as an array so the block's index reads are on a typed receiver, and reporting exactly as `table` does.
- Change the 91 tables under `test/` whose rows are one-line array literal inputs and whose block indexes that input to call `cases`, with rows, labels, and snapshots unchanged.
- Document in `docs/spinel-notes.md` the construct to avoid, the readers that avoid it, and the figures before and after, and name `cases` in `docs/examples.md` and `docs/codebase-map.md`.
- Add the archived OpenSpec change `untyped-elephant` with its proposal, design, and tasks, and no spec delta since no behavior changes.
- Record the planner's queue, the metrics row of the previous merged change, and three non-blocking quality findings in the backlog.

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding.
- Run the quality review, passed with no blocking finding and three advisories recorded in `docs/backlog.md`.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the benchmark comparison against main's recorded figures, passed.
- Run `make spec-validate` after the archive, 51 passed and 0 failed.

---

## Notes

The second part, typing the JSON reads of the language gateway and the language-server tests and the test helpers that index untyped values outside a table block, is proposed as its own queue item; `SPINEL_REF` stays at 6af548c9 until it lands. Tables were moved to `cases` only when every row matched the array literal shape, so a wrongly moved table would fail to compile or differ from its snapshot rather than pass.
