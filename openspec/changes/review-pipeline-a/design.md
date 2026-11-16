# Design

## Context

The merge phase of `.claude/workflows/deliver-change.js` calls `staleRed(m.checks)` when the merger returns `red`: a red superseded by a later green run of the same check (the scan re-run by a body edit) costs no fix round and the merger is called again. `.claude/workflows/periodic-review.js` builds its record lines and its return value from `missedOf` over the security result and the merged quality result. `continueReview` builds a continued review's text with `reviewMore`, which `securityReview` places before its closing sentence.

## Decisions

### A check run is named by its workflow file and its job

GitHub names a check run by its job alone, and a pull request's checks include every workflow of the merge commit, a branch-added one too, so a name cannot tell the real `scan` from a copy. The workflow's file path can: a new workflow is a new file. `staleRed` splits each entry into `workflow, name, status, conclusion`, requires the workflow to match `.github/workflows/<file>.yml` (or `.yaml`), and keys the last run by both; any entry without one returns false, so a malformed or older list sends the red back rather than skipping it. Alternative rejected: keying by the workflow's `name:`, which a branch-added file can copy. The merger reads the file paths from the head's workflow runs (`actions_list`, which it already holds) once, only when a check failed, so a green merge keeps its call count.

### missedOf takes the kind

`missedOf(r, kind)`: `security` keeps the strings of `SECURITY_AREAS`, any other kind the integers from 1 to `MAP_AREAS`. Each caller passes its kind. The schemas already restrict each kind, so this is a second check on what reaches the shell record line.

### The closing sentence on its own line

`continuedSecurity(more)` returns `The last security review did not complete.${more}\nRun it, every sub-task inline, and return the result.`, and `securityReview` wraps it with `intro()` and `capLine`. `reviewMore` becomes a `function` so the `js` helper of `tools/tools_test.sh`, which loads one-line constants and functions, can load it.

### The first finding

No review area remains to extend (#109 replaced `REVIEW_AREAS` with the sprint count). The sprint review's `scope` in `.claude/workflows/sprint-planning.js` names `git diff BASE TIP` with no pathspec; a case pins that line, so a path filter that would leave the record keepers out fails the tools test.

## Risks

- A merger that omits the workflow file turns every stale red into a fix round; the merger's step 2 names the form, and the red is still handled correctly, only at a round's cost.
