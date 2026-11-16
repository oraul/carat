# Proposal

## Why

Five security Lows and advisories of the review pipeline, `docs/queue-backlog.md` sprint 11 item 1 (T1). The delivery workflow's `staleRed` (`.claude/workflows/deliver-change.js:364`, the brief's line 301) keys check runs by name alone, so a workflow a branch adds with a job named like a required check (`scan`) can post a green run after the real red one and have the red read as superseded, costing no fix round (Low (4)). The periodic review's `missedOf` (`.claude/workflows/periodic-review.js:124`, the brief's line 85) accepts a security area name or an integer from either kind's result, so a quality result could carry a security name into its record and the reverse. The continued security prompt (`securityReview`, `deliver-change.js:825`, the brief's line 586) appends ` Run it, ...` right after the last file of the list, so the last path reads `- tools/x.sh Run it, every sub-task inline, ...`. The security reviewer's periodic step 5 (`.claude/agents/security-reviewer.md:36`, the brief's line 33) says a review without a result is recorded `not-run` and then started again, while the workflow retries first and records `not-run` only after the retry.

The first finding no longer holds on `main`: the `guard and gates` area of `REVIEW_AREAS` in `tools/run_state.sh`, which chose the changes that started a periodic review, was removed by #109 (sprints with a sprint-end review). Every change is now reviewed by its own security review of the whole committed diff and by the sprint's review of the combined diff `git diff BASE origin/main` with no path filter, so `tools/run_state.sh` and `.claude/workflows/deliver-change.js` are always in it.

## What Changes

- `staleRed` reads each check run as `workflow, name, status, conclusion`, the workflow being the run's file under `.github/workflows/`, and keys the last run by workflow file and name; an entry without such a file makes the red not stale. A green run of another workflow file, a branch-added one included, never supersedes a red run. The merger returns `checks` in that form, reading the head's workflow runs once with its `actions_list` tool when a check failed.
- `missedOf(r, kind)` keeps only the security area names for the security result and only the integers 1 to `MAP_AREAS` for the quality result.
- The continued security prompt puts its closing sentence on a line of its own (`continuedSecurity`), so the last file of the list stands alone; `reviewMore` becomes a function the tests can load.
- The security reviewer's periodic step 5 reads in the workflow's order: started once more, then recorded `not-run` when the retry returns no result either.
- Cases in `tools/tools_test.sh` prove each: another workflow's green run does not clear a red one, `missedOf` refuses the other kind's values, the last path of the continued prompt is alone on its line, and the sprint review's scope is the combined diff without a path filter, so both record keepers are reviewed.
- README: the stale red is superseded by a green run of the same check of the same workflow file.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/workflows/periodic-review.js`, `.claude/agents/merger.md`, `.claude/agents/security-reviewer.md`, `tools/tools_test.sh`.
- README.md: changed, the stale red's superseding run names its workflow file.
- CLAUDE.md: unchanged, it does not describe the stale red, the periodic review's record, or the continued prompts; the agents' lines still hold.
- docs/architecture.md: unchanged, it does not describe the merge phase's CI reading or the review records.
- docs/codebase-map.md: unchanged, the workflows and agents are outside its areas and no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, no editor command or action changes.
- `tools/rules.sh` is not edited.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline fix (T1) of sprint 11, part a of its review-pipeline item as the planner queued it.

Backlog headings this change covers, from its queue entry: "## The guard and gates review area leaves out the review's own record keepers" (no longer holds, see Why), "## delivery-speed security Low (4) at .claude/workflows/deliver-change.js:301", "## The security reviewer's not-run order reads reversed", "## The periodic review's missed check accepts either kind's values", "## The continued security prompt joins its sentence to the last file left".

Minor assumptions: the brief's line numbers are those of an earlier commit and are read by what they name (staleRed, missedOf, the continued security prompt, periodic step 5); the first finding's acceptance, "tools-test cases show both files reviewed", is met by a case pinning the sprint review's scope to the unfiltered combined diff, since no review area is left to add the files to; a check list from an older merger, without workflow files, reads as not stale, so the red goes back to the contributor rather than being skipped.

## Out of scope

- Adding the workflows under `.claude/workflows/` to the periodic whole-tree sweep's security areas, which name the agents' tool lists but not the workflows; it is not in the brief.
- Any change to what the merger waits for or how it decides red and green.
