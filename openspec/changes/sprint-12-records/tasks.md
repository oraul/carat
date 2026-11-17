# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh history sprint-12-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `lsp-container` and `planner-split-rule` in the diff.
- [x] 1.2 `tools/run_state.sh groom sprint-12-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-12 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-12: 13 headings groomed, 7 findings file(s) folded".

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
