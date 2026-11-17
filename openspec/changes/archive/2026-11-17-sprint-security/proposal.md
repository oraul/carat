# Proposal

## Why

Part a of the queue's `sprint-security` item (T1 pipeline defect, security Medium (7)), split from its Lows. Re-verified at 5fdd787: the line numbers of the queue line no longer hold the code (the pack places it at `sprint-planning.js:151-154`, `:164-166`, `:171`, `:183-190`, `:222` and `tools/run_state.sh:1810`, `:1817-1830`, `:2041-2044`). Of the finding, one part no longer holds: `groom` already holds a plan whose sprint security review is partial or not-run (`sprint_reviewed`, which accepts only pass or blocked) and `review-due` stays due while such a plan waits. What still holds:

- In an even sprint the whole-tree sweep can fail to start (`sprint-planning.js:153-154` logs and returns null): nothing records it, and neither `groom` nor `review-due` reads the sweep's run state, so the sprint is planned and closed with its sweep never run.
- A partial sprint security review still starts the planner (`const reviewed = ran && skeptical`) and delivers a records change whose `groom` can only hold, and the report's Security line shows a partial review like a complete one.
- The sprint security reviewer records nothing: its findings reach the run state only through the skeptic's `note` commands, so a skeptic stopped at its cap leaves a blocking finding unrecorded while the review is recorded as blocked.

## What Changes

- `sprint_reviewed` (`tools/run_state.sh`) also requires, in an even sprint, the sweep's run state `sprint-N-sweep` to record its periodic security review as pass, blocked, or partial: a sweep with no record (it failed to start) or `not-run` holds `groom` ("waits for its security review (sweep none)") and keeps `review-due` due, so `/sprint` again reviews the sprint anew.
- `sprint-planning.js` records `review sprint-N-sweep periodic-security not-run "the sweep failed to start"` when the sweep returned nothing, and starts the planner only when the security review is complete (not partial), each of its findings is recorded, the skeptic returned, and the sweep of an even sprint ran and recorded.
- The workflow records every security finding of the reviewer's merged result in the sprint's run state itself, one `note sprint-N security '<finding>'` each, in a Notes step before the skeptic, every word shell-quoted (`shellWord`, `securityNotes`); the skeptic records only the ones it disputes, as `disputed: <reason>; <finding>`, and what both missed.
- The report's Security line names a partial review and the files it left (`securityLine`), and the Sweep line points to `/sprint` again.
- The security and quality reviewer agents' sprint and skeptic modes, the README's sprint planning paragraph, and the code map's flow say who records what.
- Tests in `tools/tools_test.sh`: both refusals (a partial or not-run sprint review, a sweep that failed to start or did not run), a partial sweep accepted, the report naming a partial review, the notes recorded verbatim through the shell with no skeptic, and the planner's start condition.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the sprint pipeline has no spec under `openspec/specs/`, whose specs describe editor behavior (`skip_specs: true`).

## Impact

- `.claude/workflows/sprint-planning.js`, `tools/run_state.sh`, `tools/tools_test.sh`, `.claude/agents/security-reviewer.md`, `.claude/agents/quality-reviewer.md`.
- README.md: changed, the sprint planning paragraph says the workflow records the security findings, the skeptic its disputes, and that a sweep that did not run holds the sprint.
- CLAUDE.md: unchanged, its Sprints line (a disputed security finding is recorded, a capped or missing review is `partial` or `not-run`, never passed) stays true.
- docs/architecture.md: unchanged, it does not describe the sprint review's recording.
- docs/codebase-map.md: changed, area 1's flow names the Notes step; no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1, security Medium (7)) of the backlog lane.

Backlog headings this change covers, from its queue entry: "### Sprint planned and closed without its security review (`sprint-planning` security Medium (7))", "### Sprint security findings reach the run state only through the skeptic (`sprint-planning` security Medium (7))", "### Sprint report hides a partial security review (`sprint-planning` quality advisory)".

## Out of scope

- `mergeSecurity` dropping a `./`-spelled unreviewed file (`sprint-planning.js:96-100`, Low (5)) and groom's `listed` and `fixed` accepting an unproven removal (Low (6) and the advisory): the queue item `sprint-security-b`, which the package step adds to the pool with their three headings, left in the backlog.

Minor assumptions: a partial sweep does not hold the sprint (the brief names a sweep that failed to start; a whole-tree review at its cap would otherwise hold every even sprint, and its missed areas stand in its own run state for the planner); `groom` keeps holding with exit 0 and its "waits" line, which the records change's brief already treats as a stop; a disputed security finding is noted twice, once from the reviewer's result and once with the skeptic's reason.
