# Proposal

## Why

A sprint close starts a quality reviewer over the combined diff (two starts with its continuation), a skeptic over both reviewers' results, two record starts on the quality reviewer's read profile for the notes, and then a whole nested delivery, `sprint-N-records`, whose only work is `history` and `groom`: a second pull request, CI run, and merge for bookkeeping. The user decided on 2026-11-22: "The quality review inside the planner please"; "put on contributor to do it, we don't need an extra record lane", and made it a priority.

## What Changes

- `.claude/workflows/sprint-planning.js`: the planner in its sprint mode reviews the combined diff for quality itself and reads the security reviewer's findings against the code, returning the quality notes it keeps (a dropped one is not recorded), each security finding it disputes as disputed (never dropped), and each security finding the reviewer missed; the quality reviewer and skeptic starts, their schemas, helpers, and caps go. The security notes before the planner and the planner's notes after it are recorded by the security reviewer's new record mode, under the guard's read profile. The Records phase, its nested `deliver-change.js` run, its records-merged start, and `recordsRun`, `recordsLine`, and the CAPS entries only they used go; `recordsHeld` becomes `queueHeld`, whose security-first reason is recorded as `hold security-first` in the sprint's run state.
- `tools/run_state.sh`: `groom CHANGE` is run by any delivery's package step, the first while a sprint plan waits carrying it: it holds while the sprint or its sweep records a blocking security review no change planned after it merged since (or a later whole-tree pass superseded), or the sprint records `hold security-first` with no such merge; it refuses a second carrier while `build/plan/sprint.carrier` names another change; it leaves the marker until main holds the sprint's row. `history CHANGE` appends every lane's rows when the change carries the plan. `placed_by_sprint` reads the sprint review's commit; `review-due` says the plan waits for the next delivery's package step; `set` accepts only `hold security-first`; the records-change branches of `plan-needed`, `budget`, and `history` go.
- `tools/run_state.sh merge-main`: a conflict only in the lane queues resolves with the branch's own lane queue and main's other lane queue, so two lanes' package steps after a sprint close keep both edits.
- `.claude/workflows/deliver-change.js` `packagePlan`: history, then groom, then plan-apply (or the item's removal), with no records-change branch.
- `tools/gates.sh` findings gate and `tools/docs_lint.sh` `own_lane`: the removal allowance and the all-lanes check follow a branch appending a sprint row instead of a `sprint-N-records` name, the gate still requiring each removed entry to be filed in the backlog or removed by the plan.
- `tools/agent_guard.sh`: the runner may `set CHANGE hold security-first`; its records-merged step and the notes comment go.
- Agents and commands: `planner.md` sprint mode gains the review, `quality-reviewer.md` loses its sprint, skeptic, and record modes, `security-reviewer.md` gains a record mode, `contributor.md` package step runs groom, `runner.md`, `retrospective.md`, and `.claude/commands/sprint.md` lose the records change.
- `tools/tools_test.sh`: cases for a sprint close starting no quality reviewer, skeptic, or records run; a package start running groom when a sprint plan waits; groom's hold, carrier, and marker; history across lanes; merge-main's queue resolution; review-due with no records change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/sprint-planning.js`, `.claude/workflows/deliver-change.js`, `.claude/agents/planner.md`, `.claude/agents/quality-reviewer.md`, `.claude/agents/security-reviewer.md`, `.claude/agents/contributor.md`, `.claude/agents/runner.md`, `.claude/agents/retrospective.md`, `.claude/commands/sprint.md`, `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/gates.sh`, `tools/docs_lint.sh`, `tools/tools_test.sh`.
- README.md: changed, the pipeline steps naming the skeptic and the sprint close.
- CLAUDE.md: changed, the Sprints line (the planner's review, the next delivery applying the plan) and the Lanes line (no records change beside others, merge-main keeping each lane's queue); the Phases, planner and retrospective, and Backlog lines stay, since none names the skeptic, the quality reviewer's sprint start, or the records change, and the retrospective still runs review-due.
- docs/architecture.md: unchanged, it does not describe the sprint close.
- docs/codebase-map.md: changed, the `run_state.sh` and `docs_lint.sh` rows and the flow line.
- docs/compatibility.md, docs/actions.md: unchanged, no editor behavior changes.
- docs/goals.md: unchanged, a planning record the planner writes only when asked; its lines naming the sprint quality review and the notes starts are left for the user (see the design).
- `tools/rules.sh`: not edited.
- docs/codebase-map.md also notes the security reviewer's record mode through `recordNotes`.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change by the user's request and priority, an extra beyond Sprint 29's 3 by the user's exception.

Minor assumptions: the record starts move to the security reviewer, whose hook runs the read profile, since the brief retires every quality reviewer start and the planner records nothing; option (b) of part 4 is taken, merge-main keeping both lanes' queue edits, with the marker kept until main holds the row so the other lane still reads the sprint plan's queues; the planner's `maxTurns` grows to hold the review it takes over.

## Out of scope

- `docs/goals.md`, the feature lane's files, `tools/rules.sh`, the whole-tree sweep (`periodic-review.js`), and the delivery's own security review.
- A delivery whose planner ran before the sprint closed and packages after it; the design names the limit.
