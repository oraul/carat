# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-16-records`: take in main at #199. Checked by the merge commit on the branch.
- [x] 1.2 `tools/run_state.sh history sprint-16-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the row of `moved-review-carry` in the diff; `plugin-lazy-activate` already has its row on `bugfix/tab-close-d`, so none is appended here.
- [x] 1.3 `tools/run_state.sh groom sprint-16-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-16 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-16: 8 headings groomed, 8 findings file(s) folded, its row appended to docs/sprints.tsv".

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
