# Proposal

## Why

Five security Lows of the delivery pipeline stay open (sprint-25 review note 1, Low (6); the skeptic's double-quoted notes, Low (4), two entries; the held-finding and unpushed-finding notes, Lows (5) and (4)): a contributor-started check runs the working tree's runner, so an uncommitted edit restored afterwards could forge stage passes at HEAD that the checker skips, `diagnose` being the one stage CI leaves out and no later gate reruns; the skeptic records a disputed security finding as a double-quoted shell argument, so `$(...)` in a finding expands; and any profile that may write a note can plant a `held-finding` note, which a merged resume relabels as a merged-stamped late finding, or an `unpushed-finding` note, which a resume's package step hands over as a finding.

## What Changes

- `tools/run_state.sh check-run`, the detached runner, repeats the waiter's refusal of a tracked file differing from HEAD at its own start, so a runner over a dirty tree writes no stage record and backs no head.
- `tools/run_state.sh check`: `diagnose` (`RERUN_STAGES`) is skipped at the head only on a record backed by the recorded `phase.check`, never on a contributor's claimed head, and leaves `COMPILE_STAGES`, so no runner's compiled line skips it; the checker reruns it whenever a contributor's runner could have written its pass.
- `.claude/workflows/sprint-planning.js` and `.claude/agents/quality-reviewer.md`: the skeptic records nothing; it returns each note it keeps (a kept or missed quality finding, a disputed or missed security finding) in `notes`, and the workflow builds every note command with `shellWord` (`skepticNotes`) and runs them in one record start before the planner, so a finding holding `$(...)` is recorded literally.
- `tools/agent_guard.sh`: the read profile's `note` refuses the kinds `late-finding`, `held-finding`, and `unpushed-finding`, which only the workflow's close profile writes; `tools/run_state.sh note` refuses a `held-finding` before the push or after the merge and an `unpushed-finding` once a push is recorded.
- `tools/tools_test.sh` cases prove each, each failing before its fix.

Re-verified on main: the `open_pr.sh` heading "Fork pull requests sharing the branch name block open_pr.sh (security Low (5))" no longer holds: `7cbcf29` (#268) made `open` list only same-repository pull requests and edit and read back the one left by its number, with tests ("open_pr: open opens its own pull request beside a fork's on the branch's name" and the three after it); this change does not edit `tools/open_pr.sh`.

Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect of the backlog lane (docs/queue-backlog.md, Sprint 26 item 1), narrowed by the planner's split; the sprint quality review's continuation, the reviewer's missed and twice-investigated findings, and the moved-main merge path are left for `pipeline-lows-b`.

Out of scope: a runner that is itself the forged script can still write any record; the check's skip of every stage but `diagnose` rests on CI and main's merge gates, which rerun them, and `diagnose` now on the checker's own run. `tools/rules.sh` is not edited.

## Capabilities

### New Capabilities

None: the delivery pipeline has no spec; `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `tools/run_state.sh` (`check_run`, `check_stages`, `COMPILE_STAGES`, `RERUN_STAGES`, `add_note`, header), `tools/agent_guard.sh` (`run_state_form`), `.claude/workflows/sprint-planning.js` (`SKEPTIC`, `skepticNotes`, the skeptic notes start), `.claude/workflows/deliver-change.js` (comments of `claimFrom` and `recordLate`), `.claude/agents/quality-reviewer.md`, `.claude/agents/checker.md`, `docs/contributor-notes.md`, `tools/tools_test.sh`, `docs/codebase-map.md` (area 1).
- README.md: delivery step 4 names `diagnose` rerun by the checker and no longer compiled-skipped, and step 11 the skeptic's notes recorded by the workflow.
- CLAUDE.md: unchanged, its Agents and Sprints lines describe the skeptic and the check at a level these fixes leave true.
- docs/architecture.md: unchanged, section 10 does not describe the check's skips, the skeptic, or the note kinds.
