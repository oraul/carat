# Tasks

## 1. Stage order

- [ ] 1.1 `tools/run_state.sh`: add `gates:test-build` to `STAGE_AFTER` and say why in its comment; proved by "run_state: a parallel check with gates queued before test-build passes" and "run_state: check starts gates only after test-build ended" in `tools/tools_test.sh`

## 2. Checks

- [ ] 2.1 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
