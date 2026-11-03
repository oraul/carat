# Proposal

## Why

Compiling and testing has become the slowest part of every change: CI's Test step takes 15 to 16 minutes, the local `make check` two to three hours, and the user asked to cut compile and test time before finishing syntax highlighting. Measured with Spinel's phase report (`SP_TIMING=1`), the analysis of `test/domain_buffer.rb` grew from 2.1 seconds at #7 to 44.6 seconds at #23, with a step at #17, `edit-pipeline`: 3 percent more code but 63 percent more analysis, its re-narrowing going from 2 rounds to 5. `spinel --emit-rbs` of that program shows what widened: `ChangeRecord @inserted: untyped` although the member is pinned `Array[String]`, `Buffer#splice`, `Buffer#set_lines`, `Buffer#initialize`, `LineSplice.apply`, `grow`, and `spread` taking an `untyped` line array, and `Position @row` and `@col` untyped. Nothing catches such a widening today, so it is found only when someone measures by hand.

Reproducing on 80314d8 showed the cause is not where the request expected it. `bin/carat.rb`, the editor itself, has none of those widenings: its change records, splice, and `LineSplice` are typed, and its analysis needs 2 re-narrowing rounds. The widened entries appear only in the test programs whose table rows, which are `untyped`, reach a library method directly (`Buffer.new(input[0], ...)`, `set_lines(input[1], input[2], input[3])`, `set_lines(0, 2, [])`, `Position.new(pair[0], pair[1])`, the grammar's key codes, an ex command name). Spinel types a method's parameters once for the whole program, so in that program the parameter widens, and the `untyped` lines flow through the splice into every change record, the transactions, and the undo replay, which the analysis pays for with extra rounds over the whole library. Since #17 the buffer's line array reaches far more code than the slice assignment it replaced, which is why that change made the step. A survey of every compile root at 80314d8 found the same pattern in five test programs; every other program analyses in 22 to 25 seconds with 2 rounds.

## What Changes

- The test programs pass typed values into the library: `test/domain_buffer.rb` copies its table's line lists through a `strings` helper (the one `test/domain_edits.rb` already has) and converts its rows and columns with `to_i`; `test/domain_selection.rb`'s `buffer_of` and `pos` helpers copy and convert; `test/domain_grammar.rb` copies its key codes through an `ints` helper; `test/adapters_frame_presenter.rb` and `test/use_cases_actions.rb` pass `to_s` of their table values. Every assertion and snapshot stays the same.
- A new `make analysis-budget` target, through a new script `tools/analysis_budget.sh`, compiles `bin/carat.rb` and `test/domain_buffer.rb` to C only (`-c`), in parallel, with `SP_TIMING=1`, prints each root's analysis milliseconds and its fixpoint and re-narrowing rounds, fails when a root needs more than `ANALYSIS_ROUNDS` re-narrowing rounds (default 2), and warns, without failing, when one takes more than `ANALYSIS_MS` milliseconds (default 45000). It costs about 30 seconds. `make check` runs it before the tests, and CI runs it as its own step before the Test step.
- `CLAUDE.md` (status, Commands, Layout, the CI line, and a coding convention that test programs pass typed values into the library), `docs/architecture.md` (section 10 and the layout of section 11), and the README's command table describe the target and the rule.
- `docs/backlog.md` records the two findings this change does not fix: every test program analyses the whole library, about 22 to 25 seconds each plus its C compile, which is most of the Test step, and the test plugins' empty hashes widen the unpinned manifest members in five editor and use-case test programs at no extra round.

No editor behavior changes: no file under `carat/`, `bin/`, or `bench/` changes, so the binary and the benchmark are the same program.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a test and tooling change; `skip_specs` is set for this change.

## Impact

- `test/domain_buffer.rb`, `test/domain_selection.rb`, `test/domain_grammar.rb`, `test/adapters_frame_presenter.rb`, `test/use_cases_actions.rb`: typed values at the calls into the library; snapshots unchanged.
- `tools/analysis_budget.sh`: new, executable.
- `Makefile`: `ANALYSIS_ROOTS`, `ANALYSIS_ROUNDS`, `ANALYSIS_MS`, the `analysis-budget` target, `check`, and `.PHONY`.
- `.github/workflows/ci.yml`: an Analysis budget step before the Test step.
- `CLAUDE.md`, `docs/architecture.md`, `README.md`, `docs/backlog.md`.

This change is outside the roadmap of `docs/architecture.md` section 12: it is tooling and test hygiene the user asked for before syntax highlighting, item 8, because compile and test time slows every change.

Out of scope: the per-program cost of analysing the whole library, which needs fewer compile roots and is recorded in the backlog; the return types that widen in `bin/carat.rb` itself (methods ending in a loop or a mixed `return`, such as `UndoTree#push`, `Buffer#revert`, `Buffer#reapply`, `Dispatcher#call`, and `MainLoop#run`, and the port methods the doubles override), which are as old as the code, cost no extra round, and measured no faster when ended in `nil`; the unpinned manifest hashes; changing Spinel; and any change to the editor's code.

Assumptions recorded here instead of asked: the change records keep their `Array[untyped]` list behind `Transaction#record_at`, because that accessor already declares `ChangeRecord` and `bin/carat.rb` shows the records and the splice typed; a separate records class would change nothing the analysis sees, so the fix goes where the widening starts. The pull request title names what is typed, the tests' table values, rather than the change records the request expected, because the change records are not what changed. The budget compiles two roots rather than one: `bin/carat.rb` alone needed 2 rounds before the fix too, so it would not have caught the regression, while `test/domain_buffer.rb` covers the whole library and is where it showed.
