# Proposal

## Why

The close of a delivery loses records it could keep, in two ways that compound. The workflow records the merger's reported sha as the merged commit without resolving it (`state.merged = m.sha`, `phaseDone('merge', m.sha)`, and `closeAt = state.merged || head` for the retro and report phases in `.claude/workflows/deliver-change.js`), so a merger that returns the pushed branch head (sprint-14-records, #185: 343a3b0435d0 for the squash commit 859aae1a281b) or a mistyped hash (#169, ruby-structure-remove #188: f2d13c502fad for a5a025a15787) gets its merge phase refused by `tools/run_state.sh` (`merged_at`, correctly). And the close's record line joins every phase line and the metric line with `&&`, so that one refusal drops every later line: sprint-14-records and merge-record-check (#183) lost their merge, retro, and report phases and all 30 metric fields, filled in by hand afterwards.

## What Changes

- `tools/run_state.sh phase CHANGE NAME merged [REPORTED]`: for NAME `merge`, `retro`, or `report`, the word `merged` in place of a commit records the phase at the change's squash commit on main: the newest commit of `origin/main` (BASE), else of HEAD, whose subject ends with ` (#PR)` for the recorded pull request (`squash_commit`), which a recorded `merged` value must equal (a disagreement is refused naming both); with no pull request recorded, the recorded `merged` value as `set` checks it. Given REPORTED, the commit an agent reported as merged, a REPORTED that does not resolve to that squash commit adds a `merge-disagreement` note naming both values; the phase is still recorded at the squash commit.
- `.claude/workflows/deliver-change.js` records the merge, retro, and report phases with the word `merged`, passing the merger's sha only as REPORTED, and tells the close that the merged commit is the run state's `merged`, the squash commit, never the merger's sha.
- The close's record line runs every line whatever an earlier one did: each line is followed by `|| echo refused: N` (its 1-based position) and the lines are joined with `; `, so a refused line prints its refusal and its number and the rest, the metric line included, are still recorded. The close returns `recorded` true only when no line was refused, and a new `refused` list of the refused positions; the workflow notes each refused line by its text with the close's output.
- `tools/agent_guard.sh`'s close profile accepts `phase CHANGE NAME merged` for NAME `merge`, `retro`, or `report`, and `phase CHANGE merge merged COMMIT`.
- `.claude/agents/merger.md` and `.claude/agents/retrospective.md` say where the merged commit comes from: the squash commit on `origin/main` whose subject ends with ` (#N)`, the run state's `merged`, which the workflow records at, never the sha an agent returned; the retrospective runs the record line knowing a refused line no longer stops the rest.
- Tests in `tools/tools_test.sh`: the workflow's lines for a merger reporting the pushed head, run against a fixture repository, record the squash commit as `phase.merge`, `phase.retro`, and `phase.report` with a disagreement note naming both; a close record line with one refused phase still records the other phases and every metric field and prints the refused line's number; `phase ... merged` refuses a recorded `merged` that is not the squash commit and a change with neither a pull request nor a merged commit; the guard's close profile accepts the new forms and still refuses another word.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the pipeline's tooling only, no editor behavior (`skip_specs: true`).

## Impact

- `tools/run_state.sh`: new `squash_of_change`; the `phase` command; the header.
- `tools/agent_guard.sh`: the close profile's `phase` form; its header.
- `.claude/workflows/deliver-change.js`: the merge phase, `queue`, `CLOSABLE`, the close's lines (`closeLines`, `recordLine`), the `CLOSE` schema's `refused`, the close prompt, and the refused-line notes; the comments describing the old behavior.
- `.claude/agents/merger.md`, `.claude/agents/retrospective.md`: as above.
- `tools/tools_test.sh`: the new cases.
- `.claude/workflows/sprint-planning.js`: unchanged, it delivers its records change through `deliver-change.js`, whose close this change fixes, and already reads the run state's `merged`.
- README.md: changed, the run state paragraph says the close records the merge at the squash commit the run state resolves and a refused record no longer stops the rest (the docs gate asks for it whenever an agent or workflow file changes).
- CLAUDE.md: unchanged, its run state, agents, and gates entries stay true: no command, phase, or process step is added; `phase` keeps its name and gains an argument form the script's header lists.
- docs/architecture.md: unchanged, it does not describe the run state's records or the close.
- docs/codebase-map.md: changed, the `tools/run_state.sh` entry names the `merged` word of `phase` and `squash_of_change`; no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action changes.
- `tools/rules.sh`: unchanged.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1), Sprint 15's user-approved exception, beyond the sprint.

## Out of scope

- Rewriting the records of earlier runs, already filled in by hand.
- `flush()`'s record line before the push, which records the check and review records the gates read and stops the run on any failure, as it should.
- Writing `merged` from `phase ... merged` when the merger's own `set merged` was refused: the merger's step 7 stays the one writer of `merged`.
- The merger's `head` and the CI records, already taken from the pushed head (#183).

Minor assumptions: "the close's `recorded` says which lines were refused" is met by keeping `recorded` (true only when no line was refused) and adding `refused`, the positions the line printed, which the workflow turns into notes naming each refused line; the disagreement note is a run state note of kind `merge-disagreement`, written by `phase` itself, since the workflow cannot run git and so cannot know the squash commit; a REPORTED that git cannot resolve (a mistyped hash) counts as a disagreement.
