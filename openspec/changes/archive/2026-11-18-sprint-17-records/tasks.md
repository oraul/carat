# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-17-records`: take in a moved main. Checked by its output, "chore/sprint-17-records holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-17-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `squash-body-full` and `vim-line-commands-c` in the diff, and a rerun's "history: nothing pending".
- [x] 1.3 `tools/run_state.sh groom sprint-17-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-17 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-17: 14 headings groomed, 7 findings file(s) folded, its row appended to docs/sprints.tsv".
- [x] 1.4 Put the three backticked paths to removed findings files that `make docs-lint` refuses in prose. Checked by `make docs-lint` passing.

## 2. Review fixes

- [x] 2.1 Name the backlog heading "### Marked fold copies outlive a committed plugin edit" in `docs/queue-feature.md` instead of `vim-folds-b.md:36`, a removed findings file. Checked by `grep vim-folds-b.md docs/queue-feature.md` finding nothing and `make docs-lint` keeping the queues' budget.
- [x] 2.2 Say `round-limit-resume` is queued first of the pool's T1 defects in `docs/queue-backlog.md`, as the Pool orders it. Checked by the Decisions line.
- [x] 2.3 Say in the proposal that 5 of groom's 14 headings left `docs/backlog.md` and 9 the findings files it folds. Checked by the proposal's What Changes.
- [x] 2.4 Quote the heading in `docs/queue-feature.md` with its "### ", as the queues' Backlog lists do. Checked by the Decisions line and `make docs-lint` keeping the queues within their budget (17,966 of 17,969 bytes).
- [x] 2.5 Say in the proposal that groom folds the findings files into `docs/backlog.md`, the referent lost after the inserted count. Checked by the proposal's What Changes.

## 3. Checks

- [x] 3.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.
