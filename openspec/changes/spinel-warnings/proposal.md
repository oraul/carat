# Proposal

## Why

Spinel 93d7883b, pinned by #135, prints four warnings while carat builds: two on `carat/use_cases/windows/tab_request.rb` (its `# @rbs @target` and `# @rbs @count` pins sit in an empty `Data` class body, so they are not applied) and two on `carat/domain/utf8.rb` lines 53 and 63 (the signatures of `Utf8.boundary` and `Utf8.scalar?`, printed while building `carat-gen-config`). Every build target exits 0 on a warning, so the checker and CI pass while Spinel says a signature is not applied, and the next warning goes unnoticed the same way. The standalone `make lint` shows the cost: `test/lint.rb` calls `Carat::Json.element` but requires only `carat/testing`, so compiled alone Spinel warns `uninitialized constant Carat::Json`, exits 0, and the program raises `NameError` against its snapshot; only the test runner, where another test requires `carat/domain/json`, passed.

## What Changes

- `carat/use_cases/windows/tab_request.rb`: the two ivar pins leave the empty class body; `docs/spinel-notes.md` (Records) already says such a pin applies only to a body with a statement.
- `carat/domain/utf8.rb`: a `public_class_method :boundary, :scalar?` line at the end of `Utf8` names the two methods in every program. Spinel drops a method that nothing in the program names unless it is the last statement of its module (its `prune_unnamed_methods` pass), and then warns that the dropped method's signature is not applied; `carat-gen-config` calls only `Utf8.size_at`. The line is a no-op in Ruby, since both methods are already public, so no behavior changes. `docs/spinel-notes.md` records the cause.
- `tools/spinel_warnings.sh` (new): `check LABEL FILE...` prints every `spinel: ...: warning: ...` line of the files and fails when there is one; run with any other arguments it is the compiler `spinel-doctor` runs (through `SPINEL`), passing everything to `spinel` and adding its warning lines to `SPINEL_WARNINGS_LOG`.
- `test/lint.rb`: requires `carat/domain/json`, which it uses; a broken window the fatal warnings expose, fixed here so `make lint` passes on its own.
- `Makefile`: every target that compiles with Spinel fails when Spinel printed a warning, naming each one: `dev-build`, `test-build`, `build` (the release build, its standard error now kept in `BUILD_LOG`), `test-one` (and so `lint`), `bench`, `bench-budget`, `types`, `gen-config` (spin's standard error kept in `GEN_CONFIG_LOG`), `diagnose`, and `diagnose-one`.
- `tools/tools_test.sh`: cases with a stub toolchain prove that a warning fails each of those targets, that `build`, `diagnose`, `types`, and `gen-config` pass without one, and that the check passes a log without one.

No editor behavior changes: every test and snapshot is expected unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No editor behavior changes, so `skip_specs` is set.

## Impact

- `carat/use_cases/windows/tab_request.rb`, `carat/domain/utf8.rb`: comments and one no-op statement; allocations and rounds are expected equal to main's.
- `Makefile`, `tools/spinel_warnings.sh`, `tools/tools_test.sh`: the build targets and their test.
- `test/lint.rb`: one require; its snapshot is unchanged.
- `docs/codebase-map.md`: area 1 names `tools/spinel_warnings.sh`.
- docs/architecture.md: unchanged, it is within 9 bytes of its budget; the rule is in `docs/spinel-notes.md`, binding with its section 2.1, and the Makefile comment.
- `docs/spinel-notes.md`: the pruned-method warning and its workaround.
- CLAUDE.md: unchanged, no target, command, agent, workflow, or rule is added; the targets keep their names and only fail on one more condition.
- README.md: unchanged, no command, option, or editor behavior changes.

Outside the roadmap of `docs/architecture.md` section 12: toolchain upkeep the user asked for, sprint 7's first item.

## Out of scope

- Timing noise, Node or git hints, and any other Spinel output; the analysis budget's own time warning (`analysis budget: warning:`, not Spinel's) still never fails.
- Fixing Spinel's pass so a dropped method's signature does not warn.

Assumptions recorded here instead of asked: "the diagnose roots" covers `make diagnose` over every root and `make diagnose-one`, which runs `spinel-doctor` as `make diagnose` does; a Spinel warning is a line of the form `spinel: FILE:LINE:COL: warning: ...`, the form both warnings at this pin take; the targets the decision named are the compile targets, so `profile`, `run`, `install`, `pack`, `analysis-budget`, and `spinel-header`, which compile the programs a checked target already compiles (`bench`, `build`, `dev-build` and `test-build`) or the vendored header's generator, stay unchanged.
