# Tasks

## 1. Planning records

- [ ] 1.1 `tools/run_state.sh history sprint-11-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `ux-fixes-a` and `windows-tabs-tidy` in the diff.
- [ ] 1.2 `tools/run_state.sh groom sprint-11-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-11 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-11: 22 headings groomed, 4 findings file(s) folded".

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
