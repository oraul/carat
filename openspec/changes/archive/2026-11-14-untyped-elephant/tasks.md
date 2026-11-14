# Tasks

## 1. Measure

- [x] 1.1 Build a 6b43fe94 toolchain under `tmp/` (`make toolchain SPINEL_REF=6b43fe94de957419fd6a670fae365987b40d4f1a SPINEL_SRC=tmp/.spinel-new PREFIX=tmp/.toolchain-new`) with a local trace of the load record's rebuilds under `SP_ELAB_TRACE`, and measure `make test-build` with it at main: the `an_elab_points` builds, the `cg_methods` seconds, and the rebuilds per generated method and asking call. Verify against the 4,501 rebuilds recorded in `docs/spinel-notes.md`.
  - Result: 4,501 builds, `an_elab_points` 244 s within `cg_methods` 413 s (6af548c9: 39 builds). Per generated method: `Testing#table` 2,260, the test modules 1,887, `JsonRpcLanguageGateway` 210, FileUtils 24; each untyped `[]` asks twice (`[]`, then `new`).

## 2. The table rows

- [x] 2.1 `carat/testing.rb`: read `table`'s rows through the typed element reader `cell`, and add `cases`, whose block gets its input typed `Array[untyped]` through `list`. Verify the `Testing#table` rebuilds vanish from the trace and `make test-one T=test/domain_selection.rb` passes.
  - Result: `Testing#table` makes no rebuild; the whole runner at 6b43fe94 falls to 2,241 builds with only this file changed. In `test/domain_selection.rb` alone, `cases` takes its rebuilds from 168 to 46.
- [x] 2.2 `test/*.rb`: move every table whose rows are single lines with array literal inputs and whose block indexes its input from `table` to `cases`, by script. Verify `make test` at the pinned 6af548c9 passes with every snapshot unchanged, and measure the rebuilds at 6b43fe94 again.
  - Result: 91 of 226 table calls moved, in 56 files. `make test` at 6af548c9: 104 of 104 pass, snapshots unchanged, re-narrowing 2 rounds, 39 builds. At 6b43fe94: 1,181 builds, `an_elab_points` 79 s, `cg_methods` 131 s (from 413 s); the rest are the JSON reads (gateway 210, language-server tests 366) and test helpers and loops, the second part.

## 3. Docs

- [x] 3.1 `docs/spinel-notes.md`: name the construct to avoid, the readers that avoid it, and the figures before and after; name `cases` in `docs/examples.md` and `docs/codebase-map.md`. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
