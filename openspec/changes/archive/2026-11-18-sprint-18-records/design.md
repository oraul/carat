# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it removes the headings of `build/plan/groom.txt` from the backlog and the findings files, folds `docs/findings/*.md` into `docs/backlog.md`, appends `build/plan/groomed.md`, copies `build/plan/queue-feature.md` and `queue-backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint` (here `sprint-18`). The first start stopped at plan for a security Medium (9) at `tools/run_state.sh:449`; `groom-security-mark` fixed it and merged as #214, and the planner then revised the two lane queues at the user's request.

## Goals / Non-Goals

Goals: apply the sprint-18 plan once, with the history rows it needs, on a branch holding main. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`; editing what `groom` writes beyond the hand edits of Decisions.

## Decisions

- Run `merge-main` first; it merged `origin/main` at #214 into the branch.
- Commit the `history` rows in their own commit before `groom`, which reads them for the sprint's row.
- Commit `groom`'s output, then one hand edit docs-lint needed: commit 1dba846 unquotes the removed findings directory in the Location line of the backlog entry "Groom leaves references to the findings files it removes (sprint-17-records retro)", since groom removed every findings file and docs-lint refuses a backticked path that does not exist; that entry now carries this as evidence. The two queues stay within `QUEUE_BUDGET`.
- Fix in place the review's advisories in the files the change edits, adding no behavior: drop the backlog queue's "Security first" section and the Decisions bullet naming `groom-security-mark` in both queues, merged as #214 (b5b0aec), so the next backlog delivery does not start a change `init` refuses; cite only the user's request for the 3 features in the feature queue's Decisions, its "NEXT-SESSION.md" source not in the repository. Backlog entries are neither merged nor removed by hand: the duplicate, stale, and format notes go to the findings file for the next grooming.
- Run no `plan-apply`: `build/plan/sprint-18-records/queue-backlog.md` is the planner's reference copy only.

## Risks / Trade-offs

- The two queues now differ from `build/plan/`'s copies by the in-place fixes above; the next lane `plan-apply` or sprint plan replaces them, so the planner's next revision drops the same lines.
