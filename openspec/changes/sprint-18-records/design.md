# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it removes the headings of `build/plan/groom.txt` from the backlog and the findings files, folds `docs/findings/*.md` into `docs/backlog.md`, appends `build/plan/groomed.md`, copies `build/plan/queue-feature.md` and `queue-backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint` (here `sprint-18`). The first start stopped at plan for a security Medium (9) at `tools/run_state.sh:449`; `groom-security-mark` fixed it and merged as #214, and the planner then revised the two lane queues at the user's request.

## Goals / Non-Goals

Goals: apply the sprint-18 plan once, with the history rows it needs, on a branch holding main. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`; editing what `groom` writes.

## Decisions

- Run `merge-main` first; it merged `origin/main` at #214 into the branch.
- Commit the `history` rows in their own commit before `groom`, which reads them for the sprint's row.
- Commit `groom`'s output as written: `make docs-lint` passes on it, the two queues within `QUEUE_BUDGET`.
- Run no `plan-apply`: `build/plan/sprint-18-records/queue-backlog.md` is the planner's reference copy only.

## Risks / Trade-offs

- The backlog queue's "Security first" section still names the merged `groom-security-mark`; it is left as the plan wrote it, since the brief applies the queues as they stand, and the next backlog-lane `plan-apply` replaces the queue.
