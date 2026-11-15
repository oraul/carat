# Design

## Context

Spinel prints a warning on standard error as `spinel: FILE:LINE:COL: warning: MESSAGE` and still exits 0. `dev-build` and `test-build` already send Spinel's standard error to a timing report and copy every line but the `spinel-timing` ones to the terminal; `build` runs `spin build` with its output on the terminal; `diagnose` and `diagnose-one` run `spinel-doctor --quiet`, which captures each compile's output and keeps only the lines of its legs, so a Spinel warning never reaches the terminal there (`spinel-doctor` printed "clean" over a file with an unapplied pin). `spinel-doctor` takes the compiler from `SPINEL` when that names a file (`tools/tool_common.rb`, `find_spinel`).

The `utf8.rb` warnings come from Spinel's `prune_unnamed_methods` (`src/analyze_desugar.c`): a method whose name no node of the program holds, and that is not the last statement of its class or module body, is removed before types are read; the inline RBS pass then reports its annotation as on a node that "became a NilNode". `carat-gen-config` requires `utf8.rb` through `rc_parser.rb`, which calls only `Utf8.size_at`; `code_at` is named by `codes`, and `codes` is the module's last statement, so only `boundary` and `scalar?` warned.

## Goals / Non-Goals

**Goals:**

- No Spinel warning at this pin in any build target.
- A warning fails `dev-build`, `test-build`, `build`, `diagnose`, and `diagnose-one`, printed with its location, without an extra compile.

**Non-Goals:**

- Failing on any other Spinel output, on `make test-one`, `bench`, `bench-budget`, `types`, or `gen-config`.
- Changing what any program does.

## Decisions

- One script, `tools/spinel_warnings.sh`, holds the pattern (`^spinel: .*: warning: `) so the targets and the test agree. `check LABEL FILE...` prints the warning lines and `LABEL: Spinel printed N warning(s)` and exits 1. Alternative: a `grep` in each recipe; it would repeat the pattern five times.
- `dev-build` and `test-build` check the report they already write, after the compile status check, so a failed compile still reports first. `build` sends `spin build`'s standard error to `BUILD_LOG` (default `build/release.log`) and copies it back, as `dev-build` does, so its output still shows, then checks it; standard output still streams.
- `diagnose` and `diagnose-one` run `spinel-doctor` with `SPINEL` naming the script, which, given anything but `check`, runs `spinel` with the same arguments, copies its standard error back to the caller, appends its warning lines to `SPINEL_WARNINGS_LOG` (`DIAGNOSE_LOG`, default `build/diagnose/warnings.log`, emptied first), and exits with Spinel's status. The targets check the log after every root ran. Alternative: a separate codegen compile per root, which costs another whole-program analysis (about 55 s for the editor); the wrapper costs nothing, since `spinel-doctor`'s codegen leg, which `make check` keeps, already analyzes each root.
- `utf8.rb` keeps its five methods and names `boundary` and `scalar?` with `public_class_method`, a Ruby no-op for public methods, at the end of the module. Alternatives: moving the two methods into another file (ten call sites change), a `class << self` body (a style used nowhere else, whose generated code could differ on hot paths), or `SPINEL_KEEP_UNNAMED` (keeps every unnamed method of every program).
- `tab_request.rb` drops the pins rather than adding a statement to the body: nothing reads the members' types from them, and `focus_request.rb` and `scroll_request.rb` have the same shape without pins.
- The test drives the real targets with a stub toolchain: `PREFIX` names a directory whose `bin/` holds stub `spin`, `spinel`, and `spinel-doctor`, which the Makefile's `PATH` puts before any other, and `DEV_BIN`, `TEST_BIN`, `BUILD_LOG`, and `DIAGNOSE_LOG` point into the test's temporary directory, so nothing in the repository's `build/` is touched.

## Risks / Trade-offs

- A later Spinel may word a warning differently; the pattern matches its location prefix and the word `warning`, the form the parser's and the inline RBS pass's warnings share at this pin.
- `spinel-doctor`'s unresolved leg asks Spinel for `warning: unresolved` lines, which the wrapper also records; that leg already fails `diagnose` on any, so nothing new fails.
- The `public_class_method` line exists for the compiler; its comment says why, and `docs/spinel-notes.md` records the pass.
