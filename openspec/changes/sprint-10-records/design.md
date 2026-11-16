# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it copies `build/plan/queue-feature.md` and `queue-backlog.md`, folds `docs/findings/*.md` into `docs/backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint`. Two changes merged after the sprint plan was written: `lsp-incremental-sync` (#159) and `git-signs-trust` (#160), the latter item 1 of the plan's feature queue.

## Goals / Non-Goals

Goals: apply the sprint-10 plan once, with the history rows it needs, and leave queues that name no merged item. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`.

## Decisions

- Run `history` before `groom`, as `groom` refuses a sprint with fewer history rows than its size.
- Copy `build/plan/sprint-10-records/queue-feature.md` over `docs/queue-feature.md` after `groom`: the delivery planner wrote it to replace the sprint plan's feature queue, and `plan-apply` in the package step copies only this change's lane queue (backlog). Alternative: edit the sprint plan's file before `groom`, which would change an ignored record no commit shows.

## Risks / Trade-offs

- The sprint plan's backlog queue lands first and the delivery planner's version replaces it in the package step; the two differ by one note line, so the commit history shows both.
