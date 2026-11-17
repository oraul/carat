# Proposal

## Why

The user asked to calibrate the sprint to hold one more backlog item for now: a sprint becomes 6 counted changes, 3 features and 3 backlog changes, from sprint-17 on, while sprint-16 finishes as planned with 5. Today one constant, `SPRINT_SIZE=5` in `tools/run_state.sh`, closes every sprint at its fifth counted merge, `backlog-pick` prints the sprint's two backlog batches, `docs_lint.sh` caps the backlog lane's sprint at 2 items, and the docs and the planner say "a sprint of 5, three features and two backlog changes".

## What Changes

- `tools/run_state.sh`: the sprint size depends on the sprint's number. `SPRINT_SIZE=6` from `SPRINT_SIZE_FROM=17` on, `SPRINT_SIZE_BEFORE=5` for an earlier sprint; `sprint_state` sets `sprint_size` from `sprint_n`, and `review-due`, the sprint row (`sprint_row`, so `groom` and `sprint-row`), and `groom`'s row count read it. `PICK_BATCHES` becomes 3, the next sprint's three backlog items.
- `tools/docs_lint.sh`: a backlog lane's sprint holds at most 3 items (the feature lane 3 as before).
- `tools/tools_test.sh`: cases for sprint-16 due at its fifth counted merge, sprint-17 not due at its fifth and due at its sixth, groom refusing sprint-17 at 5 rows and its row taking 6, `backlog-pick` drawing 3 batches, docs-lint refusing a backlog sprint of 4 items, and the planner's text naming 3 backlog items.
- `docs/goals.md` records the user's decision of 2026-11-17, for now, so a later sprint can revisit it; `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, the planner, the retrospective, `/sprint`, and `sprint-planning.js` say 6 (3 + 3).
- `docs/queue-backlog.md` gets, in the package step, the exception line the brief gives under its Sprint 16 heading.

The one-pipeline-item rule and the exception rules (`EXCEPTION_MARK`, `SPRINT_EXCEPTIONS=1`) stay as they are.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the sprint rule is the delivery pipeline's, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/docs_lint.sh`, `tools/tools_test.sh`.
- `.claude/agents/planner.md`, `.claude/agents/retrospective.md`, `.claude/commands/sprint.md`, `.claude/workflows/sprint-planning.js`, `.claude/workflows/deliver-change.js` (one comment).
- CLAUDE.md: changed, the Agents section's sprint rule says 6 changes, three features and three backlog changes, from sprint-17.
- README.md: changed, the pipeline description names the size.
- docs/goals.md: changed, the sprint rule and the user's decision of 2026-11-17.
- docs/codebase-map.md: changed, the `review-due` entry names the size constants; no file is added, moved, or removed.
- docs/architecture.md: unchanged, it does not name the sprint size.
- docs/compatibility.md and docs/actions.md: unchanged, no editor behavior.
- `tools/rules.sh`: not edited.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1, user request), Sprint 16's user-approved backlog-lane exception, beyond the sprint.

## Out of scope

- The feature lane's files (`docs/queue-feature.md`, `docs/metrics-feature.tsv`).
- `SPRINT_EXCEPTIONS` and the exception rules: Sprint 16 holding two changes marked beyond the sprint (plugin-lazy-activate and this one) is left to the main session, as the plan notes say.
- The one-pipeline-item rule.

Minor assumptions: the size is keyed on the sprint number in `sprint_state` rather than on a column of `docs/sprints.tsv`, so no recorded row changes; `PICK_BATCHES` changes for every later pick, since the next pick is sprint-17's; the docs-lint cap of the backlog lane becomes 3 at once, since sprint-16's queue holds at most 2 backlog items and passes either way.
