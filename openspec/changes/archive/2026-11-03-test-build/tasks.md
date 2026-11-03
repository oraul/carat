# Tasks

## 1. One test runner

- [x] 1.1 Wrap every `test/*.rb` in a module named after its file with `main` and the `__FILE__ == $0` guard, mechanically (constants, classes, and helpers in the module, statements in `main`); verify that each file still compiles and passes on its own (`make test-one`) and that every snapshot is byte for byte unchanged.
- [x] 1.2 Add `test/runner/run_all.rb`, requiring every test and running one by name, exiting 2 for an unknown name; verify that it compiles once and that all 50 tests pass from it, and that `spin test` does not list it (it globs `test/*.rb` only).
- [x] 1.3 Return objects with typed readers instead of destructured arrays from the helpers of `test/use_cases_plugins.rb`, `test/use_cases_plugin_files.rb`, and `test/domain_grammar.rb`, and convert the line `test/lint.rb` passes to its helper with `to_s`; verify that the runner compiles and that `spinel-doctor` reports it clean.

## 2. The make targets

- [x] 2.1 Add `tools/run_tests.sh` and the `Makefile` targets `test-build`, `test-run`, `test-one`, and `diagnose-one`, change `test`, `lint`, `snapshots`, and `diagnose`, with `TEST_OPT`, `DEV_FLAGS`, `SPINEL_CACHE_DIR`, `T`, and `DIAGNOSE_SKIP`; verify that `make test` passes, that a compile failure stops before any test runs, that `make snapshots` leaves every `.expected` unchanged, and that `make test-one T=test/domain_buffer.rb` and `make diagnose-one T=test/domain_buffer.rb` pass.
- [x] 2.2 Measure the runner's build at `-O 0`, `-O 1`, and `-O 2`, plain and `--incremental` cold and warm, and choose the level; verify by the table in design.md.
- [x] 2.3 Change `tools/analysis_budget.sh` to compile roots one after another and to check a report a build already wrote (`--check`), have `make test-build` check the runner's report, set `ANALYSIS_ROOTS` to `bin/carat.rb` and the runner, and drop `analysis-budget` from `make check`; verify that `make test-build` prints the runner's rounds and that `make analysis-budget` passes.
- [x] 2.4 Have `bin/carat-gen-config.rb` write a generated file only when its text changes, so `make gen-config` no longer makes the next `make build` recompile the editor; verify that a second `make gen-config` reports both files current and the generated config check of CI still passes.

## 3. Continuous integration

- [x] 3.1 Add `tools/ci_scope.sh` and change `.github/workflows/ci.yml`: the concurrency group, the scope step and the conditions on every step, the compile cache with its key and fallback, the steps Compile the tests and Test, and `workflow_dispatch`; verify the scope script locally on a documentation-only commit, on one touching `docs/actions.md`, and on this branch, and on the pull request's own run.

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md` (status, hard rule, Stack, Commands, Layout, conventions), `docs/architecture.md` sections 2, 10, and 11, and the README's command table; verify by reading them against the `Makefile` and the workflow.
- [x] 4.2 Update `docs/backlog.md`: remove the entry on every test program analysing the whole library and the manifest-hash entry, and record the destructuring limitation; verify by reading the entries.

## Workflow follow-up

- Archive with `--skip-specs` and commit, then run the stages of `make check` and the other measured targets on that commit, each detached with its own log and a line in `build/stages/progress`.
- Run the security review on the committed branch diff.
- Push once, open the pull request, wait for CI, and squash-merge only if the targets are met; otherwise stop and report.
