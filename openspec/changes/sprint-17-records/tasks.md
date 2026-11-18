# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-17-records`: take in a moved main. Checked by its output, "chore/sprint-17-records holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-17-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `squash-body-full` and `vim-line-commands-c` in the diff, and a rerun's "history: nothing pending".
- [x] 1.3 `tools/run_state.sh groom sprint-17-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-17 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-17: 14 headings groomed, 7 findings file(s) folded, its row appended to docs/sprints.tsv".
- [x] 1.4 Put the three backticked paths to removed findings files that `make docs-lint` refuses in prose. Checked by `make docs-lint` passing.

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
