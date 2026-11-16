# Design

## Context

`tools/run_state.sh` computes `plan-needed`, `history`, and `review-due` from the run states, `docs/metrics.tsv`, and `docs/sprints.tsv`; `.claude/workflows/deliver-change.js` reads `plan-needed`'s line in its Resume start and decides the Plan phase.

## Decisions

### plan-needed alone decides the plan

The skip condition dropped `!request`: `planSkipped(state, line)` is true when the run has no merge, plan, or implement record and the line starts `not needed:`. `plan-needed` says `needed:` for a change that is not the queue's head (a new request derives a name no item heads) and for a pending proposal or finding, the only decisions the planner makes for a delivery; a brief for the head item cannot change its order, so it no longer plans. Alternative rejected: matching words such as "no other queue reordering" in the brief, which is fragile and still plans for a brief that omits them.

### A merge is a commit git knows on main

`pending_list` keeps its shape check (`merged_commit`), skips a run with a history row, and then requires `merged_on_main`: the commit resolves and is an ancestor of HEAD or of BASE (`origin/main`), as `supported` judges the resume's records. The git calls run only for the runs without a row. `append_history` reports each run with a commit-shaped `merged` value, no row, and no such commit (`history: NAME records merged VALUE, no commit on main; not appended`), so a typo is seen rather than silently pending forever.

### The exception mark is read from the queue the change was delivered from

`exception_item NAME COMMIT` reads `docs/queue.md` at `COMMIT^`, as `estimate_of` reads the size, and is true when the item `` `NAME` (`` holds `EXCEPTION_MARK` (`beyond the sprint`) before its first `)`. The mark is distinct from `the user-approved exception`, which already marks items lifted from the one-pipeline limit (`brief-only-relay`'s item read so) and leaves them counted. `sprint_state` computes `sprint_exceptions` from `sprint_names` (each name's merged commit from its history row, else its run state) and `sprint_count` over the rest. `review_due` names the exceptions on its not-due line after the count; its due line keeps every name, so `parseDue` in `sprint-planning.js` is unchanged and the sprint review covers the exception's diff. `sprint_row` and `groom`'s row check count only names outside `sprint_exceptions` toward `SPRINT_SIZE` while the row still lists every change it takes.

## Risks

- A clone that has not fetched `origin/main` sees a fresh merge as not pending until it does; every workflow start fetches first, so the next package step has it.
- `exception_item` makes one `git show` per sprint change, at most about six per call.
