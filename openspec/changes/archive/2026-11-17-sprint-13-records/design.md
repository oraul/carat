# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it removes the headings of `build/plan/groom.txt` from `docs/backlog.md`, folds `docs/findings/*.md` into it, appends `build/plan/groomed.md`, copies `build/plan/queue-feature.md` and `queue-backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint` (here `sprint-13`). No change merged after the sprint plan was written.

## Goals / Non-Goals

Goals: apply the sprint-13 plan once, with the history rows it needs. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`; editing what `groom` writes beyond a line `make docs-lint` refuses.

## Decisions

- Run `history` before `groom`, as `groom` refuses a sprint with fewer history rows than its size.
- Commit `groom`'s output as written, but where a folded finding names a findings file `groom` removes in backticks, `make docs-lint` fails on a path that no longer exists; such a line names the file in prose instead, as in sprints 10 and 12.

## Risks / Trade-offs

- The plan's queues are taken as the planner wrote them; a reorder belongs to the next planner run, not to this records change.
