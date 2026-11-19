# Design

## Context

The merged commit reaches the run state two ways: the merger's `set CHANGE merged SHA` (step 7 of `.claude/agents/merger.md`) and the close's `phase CHANGE merge merged REPORTED` (`mergeDone` in `.claude/workflows/deliver-change.js`). Only the first wrote `merged`; when it did not run or was refused, the second still recorded `phase.merge` at the verified squash commit, and every counter that reads `merged` missed the change.

## Decisions

- Write rather than refuse. Refusing a merge phase without `merged` would leave the close's line refused and both keys empty, the worse state. The phase has just verified its commit on main by the same checks `set merged` applies (`merged_at`, `squash_commit`), so it records that commit as `merged` too. `merged` is written before `phase.merge`, so an interrupted write leaves at worst a counted merge without its phase, never the reverse.
- A recorded `merged` naming a different commit refuses the phase, naming both, as `squash_of_change` already does once a pull request is recorded; the explicit-commit form had no such check.
- Name, do not count. A run state with `phase.merge` and no `merged` (one written before this change) is named by `review_due` in a `not due` line that holds the sprint until `set NAME merged COMMIT` records it, the fix the line spells out. Counting it from `phase.merge` would guess at a record the pipeline is meant to hold; holding is one command away from resolved and never silent. The due line keeps its fixed form, which `sprint-planning.js` parses.
- Review runs (`REVIEW_RUNS`) and changes with a history row are left out: no sprint counts the first, and the second is already counted from its row.

## Risks

- A stale run state of an abandoned change holding only `phase.merge` would hold the sprint; the line names it and the fix, so it is resolved in one command.
