# Tasks

## 1. Planning records

- [ ] 1.1 `tools/run_state.sh merge-main sprint-16-records`: take in main at #199. Checked by the merge commit on the branch.
- [ ] 1.2 `tools/run_state.sh history sprint-16-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows in the diff.
- [ ] 1.3 `tools/run_state.sh groom sprint-16-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-16 row to `docs/sprints.tsv`. Checked by its output.

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
