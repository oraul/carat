# Proposal

## Why

Compiling and testing is the slowest part of every change, and the user asked for compile and test to take two minutes at most, using parallelism only where Spinel or spin officially support it. Measured on 04f742d, one test program compiles in about 60 to 85 seconds and runs in a fraction of a second: Spinel's whole-program analysis (about 23 seconds) and the C compile of about 5 MB of C, repeated for each of the 50 programs under `test/`, because every program requires the whole library. `make test` took 17 minutes locally (1,021 seconds), `make diagnose` 40 minutes (2,397 seconds, spinel-doctor on 52 roots, three analyses each), `make check` about an hour, and CI's Test step 16 minutes of a 17.5 minute job on #24. `docs/backlog.md` records the cause as "Every test program analyses the whole library".

## What Changes

- Every test program becomes a module named after its file (`test/domain_buffer.rb` declares `DomainBufferTest`) whose `main` is the test: its constants, classes, and helper methods move into the module (helpers as `def self.name`), its statements into `def self.main`, and the file ends with `DomainBufferTest.main if __FILE__ == $0`, which Spinel folds statically (true when the file is the compile root, false when it is required). The transformation is mechanical; every assertion and every snapshot stays byte for byte the same.
- A new test runner, `test/runner/run_all.rb`, requires every test and runs the one its argument names (an unknown name exits 2). It sits one directory below `test/`, where `spin test` does not look, so it is never a test program of its own. Each test still runs in a process of its own, with its own output, exit status, and snapshot.
- A new `tools/run_tests.sh` runs tests from a compiled runner and compares each test's standard output and error, merged as `spin test` compares them, with its `.expected` snapshot, requires exit status 0, prints a diff for a failure, and fails a test without a snapshot.
- The `Makefile`: `make test` is `make build`, `make test-build` (compile the runner once), then `make test-run` (run every test from it); a compile failure stops before any test runs. The runner, a single test, and spinel-doctor's builds use Spinel's documented development modes, `-O 0` (`TEST_OPT`) and, for the runner and a single test, `--incremental` with `SPINEL_CACHE_DIR` under `build/`; the release binary keeps `spin build` at `-O 2`. New `make test-one T=test/NAME.rb` and `make diagnose-one T=path` iterate on one file; `make lint` becomes `make test-one T=test/lint.rb`; `make snapshots` rewrites every snapshot from the runner; `make diagnose` runs on `bin/*.rb` and the runner only, and `make check` skips its build leg, since it has just built every root.
- The analysis budget moves into the test build: `make test-build` compiles the runner with `SP_TIMING=1` and checks its report through `tools/analysis_budget.sh --check`, so the budget covers the library and every test's calls into it at no extra analysis. `make analysis-budget` keeps compiling roots on demand (now `bin/carat.rb` and the runner, one after another, without background processes) and leaves `make check` and CI.
- Three test helpers that returned several values in an array return an object with typed readers instead (`use_cases_plugins.rb`, `use_cases_plugin_files.rb`, `domain_grammar.rb`), and `lint.rb` converts one line with `to_s`: inside a method the pinned Spinel loses the types of an array destructured into locals, which failed to compile in one test and left unresolved calls that spinel-doctor reports in the others.
- CI (`.github/workflows/ci.yml`): a concurrency group cancels superseded runs; a first step, `tools/ci_scope.sh`, skips the checks when only documentation no test reads changed, and on a push to `main` whose tree is the head of a pull request whose check passed, while the job still runs and reports so a required check passes; the runner's units of C are cached with `actions/cache` under a key of the Spinel commit, `TEST_OPT`, and the OS, with a fallback restore key, and a push to `main` always compiles the runner so `main`'s cache stays warm; the steps become Build, Compile the tests, Test, and the allocation budget; `workflow_dispatch` runs it by hand.
- `bin/carat-gen-config.rb` rewrites `carat/domain/default_config.rb` and `carat/plugins/registry.rb` only when their text changes, so a warm `make check` does not recompile the release binary because `make gen-config` touched them.
- Documentation: `CLAUDE.md` (status, hard rule, Stack, Commands, Layout, conventions), `docs/architecture.md` sections 2, 10, and 11, the README's command table, and `docs/backlog.md` (the entry on every test analysing the whole library is removed, the manifest-hash entry is removed as moot, and the destructuring limitation is recorded).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a test, build, and CI change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- `test/*.rb` (all 50, wrapped; four with the fixes above), new `test/runner/run_all.rb`; snapshots unchanged.
- `Makefile`, `tools/analysis_budget.sh`, new `tools/run_tests.sh` and `tools/ci_scope.sh`, `.github/workflows/ci.yml`.
- `CLAUDE.md`, `docs/architecture.md`, `README.md`, `docs/backlog.md`.
- `bin/carat-gen-config.rb` writes a generated file only when its text changes; before, every `make gen-config` touched both files and made the next `make build` recompile the editor for nothing. No file under `carat/` or `bench/` changes: the editor and the benchmark are the same programs.

This change is outside the roadmap of `docs/architecture.md` section 12: it is the second change of the compile and test time effort the user asked for before more features.

Out of scope: changing Spinel or spin; parallel compiler processes of the project's own (`make -j` over programs, background or pooled compiles), since the user allowed only the parallelism Spinel and spin document (Spinel's `--jobs`, which `--incremental` uses for its units); the release build and the benchmark's build, which keep `-O 2`; shortening the smoke test's waits; the library's own widened return types.

Assumptions recorded instead of asked: "run once" is read as one compile and one process per test from the same binary, not one process for all tests, so each test keeps its own exit status, output, and fresh process state exactly as before (running 50 processes costs about 5 seconds plus the smoke test's 10); the smoke test is part of the runner and runs after `make build`; `make snapshots` writes standard output and error together, as `make test-run` and `spin test` compare them (no test writes to standard error, so no snapshot changes); `make check` and CI check the analysis budget on the runner alone, a superset of the library's call sites that the editor's own root never exceeded.
