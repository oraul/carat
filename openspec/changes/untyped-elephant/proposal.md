# Proposal

## Why

From Spinel 2440954d1 on, each `[]` call on a receiver Spinel types `untyped` makes code generation rebuild the load record, Spinel's map of where each statement runs, by walking the whole program: the test runner's code generation went from 39 rebuilds at 6af548c9 to 4,501 at 2440954d1 and at 6b43fe94, and from about 125 s to 412 s. #123 pinned `SPINEL_REF` back to 6af548c9, so carat cannot take a newer Spinel until it stops feeding untyped receivers to `[]`. A traced build at 6b43fe94 (each rebuild attributed to the method being generated and the call that asked) names the main cause: `Carat::Testing#table` reads each row as `row[0]`, `row[1]`, `row[2]` on an untyped row, and Spinel generates that body once per table call, which made 2,260 of the 4,501 rebuilds. Most of the rest are the table blocks' own `input[i]` reads, since a table yields its input untyped.

## What Changes

- `Carat::Testing#table` reads its rows through a private typed element reader, `cell`, `(Array[untyped], Integer) -> untyped`, so its body makes no untyped `[]` call.
- `Carat::Testing#cases` is added: a table whose every input is an array literal, its block getting the input typed `Array[untyped]` through the reader `list`, so the block's `input[i]` reads are on a typed receiver. It reports exactly as `table` does.
- The 91 tables under `test/` whose every row is one line with an array literal input and whose block indexes that input call `cases` instead of `table`. Rows, blocks, labels, and snapshots are unchanged.
- `docs/spinel-notes.md` names the construct to avoid (a `[]` on an untyped receiver; a `.to_s` or `.to_i` after the read does not help), the readers that avoid it, and the figures before and after. `docs/examples.md` and `docs/codebase-map.md` name `cases`.

No editor behavior changes: only the test harness and the tests' calls of it change, and every snapshot stays as it is.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes, so `skip_specs` is set.

## Impact

- `carat/testing.rb`: `table` through `cell`; `cases`, `list`, `cell` added.
- `test/*.rb`: 91 `t.table(` calls become `t.cases(` in 56 files.
- `docs/spinel-notes.md`, `docs/examples.md`, `docs/codebase-map.md`.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes; its coding conventions already ask for typed table values.
- README.md: unchanged, no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, section 10 describes the test machinery without naming the table helpers.
- `SPINEL_REF` stays at 6af548c9; the 6b43fe94 measurements use a separate toolchain under `tmp/`.

Outside the roadmap of `docs/architecture.md` section 12: compile-time work the user asked for, so carat can follow Spinel past 2440954d1.

## Split

The brief asks for the rebuilds at 6b43fe94 to fall near the count at 6af548c9, and to split at the start if that is more than one reviewable pull request. It is: the remaining untyped `[]` calls after this part are the JSON readers' (`JsonRpcLanguageGateway`, 210 rebuilds, and the language-server tests' `Carat::Json.parse(...)[...]` chains, about 350), which change production code of the language gateway, and scattered test helpers and loops (about 600, under 40 each). This change delivers the first part, the table rows, the main cause; the second part, typing the JSON reads and the remaining test helpers, is proposed as its own item for the planner to place (it overlaps the queued `compile-horse`, which measures and removes the then largest compile-time cost).

Out of scope: the JSON readers and the language gateway; the test helpers and loops that index untyped values outside a table block; the bundled packages (FileUtils makes 24 rebuilds); changing `SPINEL_REF`; the planner's queue decisions in the brief; the `docs/spinel-notes.md` wording of the pin value (#123 quality note 4, folded into `spinel-workarounds`).

Assumptions recorded here instead of asked: "near the count at 6af548c9" is met for this part by the reduction it measures, with the remainder named above for the second part; a table is moved to `cases` only when a script finds every row on one line with an array literal input and the block indexing it, the others stay on `table`.
