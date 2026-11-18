# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it removes the headings of `build/plan/groom.txt` from `docs/backlog.md`, folds `docs/findings/*.md` into it, appends `build/plan/groomed.md`, copies `build/plan/queue-feature.md` and `queue-backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint` (here `sprint-16`). One change merged after the sprint plan was written: `moved-review-carry` (#199), the plan's security-first item, which the branch takes in through `merge-main` before `history` and `groom` run.

## Goals / Non-Goals

Goals: apply the sprint-16 plan once, with the history rows it needs, on a branch holding #199. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`; editing what `groom` writes beyond a line `make docs-lint` refuses.

## Decisions

- Run `merge-main` first, so `moved-review-carry`'s committed history row is seen by `history` and its findings file is folded by `groom`.
- Run `history` before `groom`, as `groom` refuses a sprint with fewer history rows than its size.
- Commit `groom`'s output as written unless `make docs-lint` refuses a line, as with a folded finding naming a removed findings file in backticks in sprints 10, 12, and 13.
- Leave the delivered security-first section to the package step's `plan-apply`, whose backlog queue the delivery planner wrote with it removed.

## Risks / Trade-offs

- The plan's queues are taken as the planner wrote them; a reorder belongs to the next planner run, not to this records change.
- `make docs-lint` refused one folded line, a backticked path to the removed `vim-line-commands-b` findings file; it is put in prose, as in sprints 10, 12, and 13, the only hand edit.
- `history` appended `moved-review-carry`'s row and not `plugin-lazy-activate`'s, which was appended on the feature lane's next branch (`bugfix/tab-close-d`) and is not on main. `sprint_row` reads only history rows, so the sprint-16 row `groom` wrote names `moved-review-carry`, the next sprint's security-first item, in place of `plugin-lazy-activate`, and its figures follow. It is committed as written, since the brief allows no hand edit of `groom`'s output and the missing row's figures are not on main; the defect, `sprint_row` skipping a merged change without a row while `sprint_names` counts it, is reported for a backlog change.
