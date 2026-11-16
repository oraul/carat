# Tasks

## 1. Planning records

- [ ] 1.1 `tools/run_state.sh history sprint-10-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `markdown-reading-b` and `git-signs-trust` in the diff.
- [ ] 1.2 `tools/run_state.sh groom sprint-10-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-10 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-10: 5 headings groomed, 8 findings file(s) folded".
- [ ] 1.3 `docs/queue-feature.md`: copy the delivery planner's feature queue, with `git-signs-trust` removed. Checked by `make docs-lint`.

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
