# Tasks

## 1. Path classes

- [x] 1.1 Move `documentation` from `tools/ci_scope.sh` into `tools/rules.sh`, counting a `LICENSE` file, and add `TOOLS_RE` beside it; proved by the `ci_scope` LICENSE case and the `TOOLS_RE` coverage case in `tools/tools_test.sh`

## 2. The local check

- [x] 2.1 Scope `check_stages` in `tools/run_state.sh` to the paths changed since the merge base, recording a scoped stage as passed with the note `scoped`; proved by the `run_state: check` docs-only, no-tools, and tools cases in `tools/tools_test.sh`
- [x] 2.2 Carry main's figures in `bench_compare` when the metrics stage was scoped; proved by the `run_state: bench carries main's figures` case

## 3. CI

- [x] 3.1 Write `tools=` from `tools/ci_scope.sh` and run the `Tools` step on it and `Docs lint` on every pull request in `.github/workflows/ci.yml`; proved by the `ci_scope: tools` cases

## 4. Makefile and docs

- [x] 4.1 Drop the stale analysis figures from the Makefile's budget comment
- [x] 4.2 Update area 1 of `docs/codebase-map.md`, the README pipeline section, and `docs/architecture.md` section 10; run `make docs-lint`, `make tools-test`, `make gates`, and `make spec-validate`
