# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh history sprint-10-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `markdown-reading-b` and `git-signs-trust` in the diff.
- [x] 1.2 `tools/run_state.sh groom sprint-10-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-10 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-10: 5 headings groomed, 8 findings file(s) folded".
- [x] 1.3 `docs/queue-feature.md`, `docs/queue-backlog.md`: copy the delivery planner's queues, with `git-signs-trust` removed. Checked by `make docs-lint`.
- [x] 1.4 `docs/backlog.md`, `docs/queue-backlog.md`: drop the backticks of the two nonexistent paths `make docs-lint` names. Checked by `make docs-lint`, paths all exist.

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
