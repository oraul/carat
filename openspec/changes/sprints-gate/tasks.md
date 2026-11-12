# Tasks

## 1. Records-only paths

- [x] 1.1 `tools/gates.sh` (`settled_at` and the header comments of the security gate and `settled_at`): accept `docs/sprints.tsv` beside `docs/metrics.tsv`. Tested by "gates: security passes after the sprint row only" and "gates: security refuses a code change beside the sprint row" in `tools/tools_test.sh`.

## 2. Checks

- [ ] 2.1 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`, all pass.
