# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-18-records`: take in a moved main. Checked by its output, "merged origin/main into chore/sprint-18-records".
- [x] 1.2 `tools/run_state.sh history sprint-18-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `background-default` and `groom-security-mark` in the diff, and a rerun's "history: nothing pending".
- [x] 1.3 `tools/run_state.sh groom sprint-18-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-18 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-18: 4 headings groomed, 7 findings file(s) folded, its row appended to docs/sprints.tsv", and the two queues equal to `build/plan/`'s.

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
