# Proposal

## Why

A merge refused because `main` moved has no path. In #169 CI was green and GitHub refused the merge (405) after #168 merged and `docs/codebase-map.md` conflicted; the contributor merged main with `tools/run_state.sh merge-main`, but `push --ci-fix` refused the push with no red CI, and the run stopped, costing a second full run. With two lanes merging into one `main`, and a conductor coming that runs them unattended, this recurs.

## What Changes

- `.claude/workflows/deliver-change.js`: the merge loop gets one main-moved path. When the merger reports CI green, not merged, and `main_moved` (a new MERGE field: the pull request conflicts with main, or GitHub refused the merge because the branch is behind main or conflicts with it), a `moved` contributor start runs `merge-main` in the lane, `verify()` reruns the check, the quality and security reviews carry over to the merged head when the checker's `tools/run_state.sh moved` line says no file of the change changed (else they run again), a `push` start pushes once with `push --main-moved`, and the loop waits for CI and merges again, no new run and no fix round. A second refusal in one run (`main_moved` in the run state or this start) stops. `first.ci` keeps the green read before the move (`verdict` records the first result only). A conflict both sides changed the same logic in stops the `moved` start, which names the files.
- `tools/run_state.sh`: `push --main-moved`, counted as `main_moved`, at most one a run, needs a recorded push other than HEAD that does not hold `origin/main` (BASE) and a HEAD that does; an unknown push kind is now refused instead of ignored. A new `moved CHANGE COMMIT` command says whether the merge changed a file the change touches (outside the records-only paths) since the reviewed commit.
- `tools/gates.sh`: `gate_pushes` counts `main_moved` (a run state without it reads 0) and refuses a second one.
- `tools/agent_guard.sh`: the contributor may run `push CHANGE --main-moved`; the read profile (checker) may run `moved`.
- `.claude/agents/merger.md` reports `main_moved`; `.claude/agents/contributor.md` gets the `moved` mode.
- `tools/tools_test.sh`: cases for the main-moved push counted once and a second one refused, the gate counting it, `moved` keeping and rerunning the reviews, the workflow helpers (`mainMoved`, `carryFrom`, `carried`, `movedTask`), `first.ci`, and the guard.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the merge loop is the delivery pipeline's, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/merger.md`, `.claude/agents/contributor.md`, `tools/run_state.sh`, `tools/gates.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`.
- CLAUDE.md: changed, the Git workflow push count names the main-moved push (the budget leaves no room for more; README.md describes the path).
- README.md: changed, the pipeline description names the main-moved path and push.
- docs/codebase-map.md: changed, the `run_state.sh` entry names `moved` and `push --main-moved`; no file is added, moved, or removed.
- docs/architecture.md: unchanged, it does not describe the merge loop or the push kinds.
- docs/compatibility.md and docs/actions.md: unchanged, no editor behavior.
- `tools/rules.sh`: not edited.
- This run is judged by main's workflow and gates, which have no main-moved path yet: a move of main while it waits to merge stops it as #169 stopped.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (autonomy plan item 1), a sprint backlog item by the user's decision.
