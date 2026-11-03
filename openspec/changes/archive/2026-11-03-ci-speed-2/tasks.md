# Tasks

## 1. Measurements

- [x] 1.1 Read the cache result and step times of the CI runs of #25 and #26 and reproduce #26's misses locally with `--cache-stats` (the runner at 52dc571 into an empty cache, then at 0b563a3); verify by the table in design.md.
- [x] 1.2 Compile `bin/carat.rb`, `bin/carat-gen-config.rb`, and `bench/keys.rb` at `-O 2` and with the development flags cold and warm, and the runner cold under `--no-inline-hot` and three unit sizes; verify by the table in design.md.
- [x] 1.3 Run every scenario of `bench/run.sh` on the benchmark built at `-O 2` and at `-O 0 --incremental` and compare the allocations per key; verify that objects and bytes are identical for all 30 scenarios.

## 2. The make targets

- [x] 2.1 Add `make dev-build` (`bin/carat.rb` with `DEV_FLAGS` into `build/dev/carat`), `CARAT_BIN` read by `test/smoke_editor.rb`, and `TESTS` for `make test-run`; verify that `make dev-build` compiles, that `make test-run TESTS=test/smoke_editor.rb CARAT_BIN=build/dev/carat` passes with the snapshot unchanged, and that `make test` still runs the smoke test on `build/bin/carat`.
- [x] 2.2 Build `make bench-budget` with `DEV_FLAGS` into `build/bench/keys-budget`; verify that it passes with `lh` at 27.0 objects per key, as at `-O 2`, and that a second run compiles no unit.
- [x] 2.3 Print each development build's analysis time and its units of C compiled and missed (`UNIT_SUMMARY` in `make test-build`, `make dev-build`, and `make bench-budget`); verify in their output.

## 3. Continuous integration

- [x] 3.1 Change `.github/workflows/ci.yml`: hash `bench/` into the compile cache key; on pull requests run `make dev-build` instead of `make build`, and the tests with `CARAT_BIN=build/dev/carat`; on a push to `main` always run the three development builds and `make build` with the smoke test on the release binary; verify on the pull request's own run that every step passes and the job takes under two minutes.

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md` (status, Commands, Layout), `docs/architecture.md` section 10, and the README's command table; verify by reading them against the `Makefile` and the workflow.

## Workflow follow-up

- Run `make check` and the changed targets on the committed tree, each detached with its own log and a line in `build/stages/ci2/progress`.
- Run the security review on the committed branch diff.
- Push once, open the pull request, wait for CI, and squash-merge only if the job is under two minutes; otherwise stop and report the floor.
