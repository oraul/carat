# Design

## Context

`groom` (`tools/run_state.sh`) applies a waiting sprint plan once, only from the sprint's records change, after `history` has appended the sprint's history rows; it removes the headings of `build/plan/groom.txt` from `docs/backlog.md`, folds `docs/findings/*.md` into it, appends `build/plan/groomed.md`, copies `build/plan/queue-feature.md` and `queue-backlog.md`, and appends the sprints row, retiring the marker `build/plan/sprint` (here `sprint-17`). The first run stopped on `groom`'s refusal of a duplicate line whose text quotes the word security; the planner's sprint mode revised `build/plan/` in place, dropping that line and writing the user's Sprint 18 queues.

## Goals / Non-Goals

Goals: apply the sprint-17 plan once, with the history rows it needs, on a branch holding main. Non-goals: any code or tool change; grooming the backlog beyond the plan's `groom.txt`; editing what `groom` writes beyond a line `make docs-lint` refuses.

## Decisions

- Run `merge-main` first; the branch already held `origin/main` at #206.
- Keep the history commit of the first run (`history` rows of `squash-body-full` and `vim-line-commands-c`); `history` reruns with nothing pending.
- Commit `groom`'s output as written unless `make docs-lint` refuses a line, as in sprints 10, 12, 13, and 16.

## Risks / Trade-offs

- The plan's queues are taken as the planner wrote them; a reorder belongs to the next planner run, not to this records change.
- `make docs-lint` refused three backticked paths to removed findings files: two Location lines in `docs/backlog.md` naming the `tab-close-d` findings file and one queue line in `docs/queue-backlog.md` naming the `vim-folds-b` findings file. They are put in prose, the only hand edit.
- The duplicate entry on a resumed records change losing the planner's files stays twice in `docs/backlog.md` until `groom-proof` lets `groom` remove a duplicate whose text only mentions security.
