# Tasks

## 1. Stage order

- [x] 1.1 `tools/run_state.sh`: add `gates:test-build` to `STAGE_AFTER` and say why in its comment; proved by "run_state: a parallel check with gates queued before test-build passes" and "run_state: check starts gates only after test-build ended" in `tools/tools_test.sh`

## 2. Review fixes

- [x] 2.1 `proposal.md`: the assumption on gates' start says gates can start once the fast free stages end, so the pair delays it by up to test-build's remaining time (quality advisory at proposal.md:34)

## 3. Checks

- [x] 3.1 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
