# Tasks

## 1. Scope

- [x] 1.1 Write `compile=` from `tools/ci_scope.sh` (`CACHED`, the probe's hit); proved by the `ci_scope` equal-tree cached, equal-tree uncached, differing-tree, and pull request compile cases in `tools/tools_test.sh`

## 2. Workflows

- [x] 2.1 Make `.github/workflows/ci.yml` pull requests only, the job `spin` kept, without the release build, its smoke test, or main's measurement save
- [x] 2.2 Add `.github/workflows/main.yml` for pushes to `main` and runs by hand: the probe, the scope, the checks on `run`, the compiling steps on `compile`; both proved by the `ci workflows` cases in `tools/tools_test.sh`

## 3. CI stages

- [x] 3.1 Keep a fractional step in `ci_stages` of `tools/run_state.sh`; proved by the `run_state: ci-stages records a fractional step` case

## 4. Docs

- [x] 4.1 Update the Makefile's CI comment, area 1 of `docs/codebase-map.md`, the README pipeline section, and `docs/architecture.md` section 10; run `make docs-lint`, `make tools-test`, `make gates`, and `make spec-validate`
