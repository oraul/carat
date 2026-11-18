# Design

## Context

`plan_needed` (`tools/run_state.sh`) takes the head item as written unless a pending change, merged with no history row, holds a retro, overrun, or periodic note; a sprint's records change applies the next queue the sprint planner wrote from those same notes, yet the notes of a change merged before it stay pending until the next history row, so the next delivery starts a planner that changes nothing. An item with no estimate is taken with `estimated -`. The area plan of `deliver-change.js` called a pack current only when its `Locations:` line listed every location the change edits, so a current pack missing one location was scouted again in full. `mergerCap` gave 12 calls with two waits and 2 per wait beyond, while a first green is 7 calls of work and 2 per wait, so three waits and a few extra reads overran it. The package step commits only records, but nothing told it before the push that it had edited a reviewed file. `check_paths` of `tools/docs_lint.sh` reads the lane queues, whose item for the change names the paths it removes.

## Decisions

- A pending change's notes count only while no sprint records change (`sprint-N-records`, with a merged commit) merged after the change's merge commit (`descends`); the records change itself stays counted, since its notes come after its sprint's plan. An unestimated head item is `needed`, the line naming it, since the estimate sets the caps and the budget.
- A pack is current when its `Commit:` is the head's main or its files read are unchanged since; the locations it lacks are returned as `unread` beside it. A needed area all of whose locations' paths (the part before `:line`) the brief names is moved to `named` by `scoutTargets` and starts no scout. The contributor's prompt lists the locations no pack covers, to read itself. The scout file's reuse step follows the same rule.
- `FIXED_CAPS.merger` becomes the work allowance, 10 (seven one-call steps and a margin of three), and `mergerCap` adds 2 for every wait; `maxTurns` is 10, 2 for each of the seven waits 30 minutes holds, and the margin of 5: 29.
- `reviewed-edits CHANGE` reads the commit of the `review.security` pass record, the one the push gate settles, and lists `git diff --name-only COMMIT` (commits and working tree) and untracked files outside `RECORDS_RE`; no pass record exits 1 with its reason. It reads only, so the guard allows it to the contributor.
- `check_paths` drops spans on the lines of `docs/queue-feature.md` and `docs/queue-backlog.md` whose item starts with the change's name in backticks; the change is `DOCS_LINT_CHANGE`, else the part of the branch name after its type, so the check clone, which checks out the branch's name, needs no variable.

## Risks

- A note recorded after the sprint plan by a change merged before the records change is no longer counted; the sprint's changes are all merged before its planning starts, so such a note is a records-run note, which stays counted.
- A brief that names a path without the change editing what a scout would have read leaves the contributor to read it; it holds the same brief and opens only the locations it edits.
- A larger merger cap can hide a slow merger; the waits are counted from its own minutes, and its work allowance is lower than before.
