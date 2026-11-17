# Tasks

## 1. Planning records

- [ ] 1.1 `tools/run_state.sh history sprint-13-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `bar-colors` and `tab-close` in the diff.
- [ ] 1.2 `tools/run_state.sh groom sprint-13-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-13 row to `docs/sprints.tsv`. Checked by its output.

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
