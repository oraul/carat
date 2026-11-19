# Proposal

## Why

`review_due` counts every change merged since the last sprint row but one marked beyond the sprint (`SPRINT_EXCEPTIONS`), so it counted two T0 items among sprint-19's six, and at 5c94cc0 it counts `delivery-guards-b` and `merged-record` in sprint-21 although the user-approved exception line under the backlog queue's Sprint 21 heading says they run outside the 3. A sprint then closes before its planned items merged, and the sprint row, its review, and the next plan cover the wrong changes.

This is a pipeline defect outside the roadmap of `docs/architecture.md` section 12, run by the user-approved exception of Sprint 21.

## What Changes

- `tools/run_state.sh`, `queue_class` (new): reads the queue at the parent of a change's merged commit and at that commit and classes the change: `t0` (its item's first parenthesis starts with `T0`), `outside` (a paragraph starting `The user-approved exception` names it, backticked, in a clause between semicolons that holds `outside the 3`, before that clause's `run` or `runs`), `beyond` (its item's first parenthesis carries `beyond the sprint`), `sprint` (a numbered item, or the exception line's item, under a `## Sprint N` heading), `pool` (an item under any other heading), or nothing when no queue names it.
- `tools/run_state.sh`, `sprint_state`: a change counts when it is a sprint item, a split part of a counted change (its name with one trailing `-x` letter removed equals a counted change's name or that name's own stem), or named by no queue (a history row or a renamed delivery the queue cannot class, counted as before); a T0 change, one outside the 3, one beyond the sprint, and a pool item are left out, every one of them (the cap of one, `SPRINT_EXCEPTIONS`, is removed). `sprint_uncounted` lists the left-out changes, which `sprint_row` and `groom` read in place of `sprint_exceptions`, so the sprint row, `groom`'s row check, and `review-due` agree.
- `tools/run_state.sh`, `review_due`: the not-due line names the left-out changes by reason, `; not counted, beyond the sprint: ...`, `; not counted, outside the 3: ...`, `; not counted, T0: ...`, `; not counted, not a sprint item: ...`, in that order, each present only when it holds a change. The due line keeps its fixed form, which `sprint-planning.js` parses.
- `tools/tools_test.sh`: cases proving a T0 change left out, a change the exception line puts outside the 3 left out while a change named after its `run before` is not, a split part of a sprint item counted, a pool item left out, and the printed reasons; the exception fixture's queue gains its `## Sprint 1` heading, and the case after the sprint's first beyond-the-sprint change now leaves out the second too.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- A rename written only in prose (`spinel-bump` delivered as `spinel-catchup`) is not parsed: a delivered name no queue holds is counted as before.
- The due line, which `sprint-planning.js` parses, prints no reasons.
- No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- README.md: the sprint planning paragraph says which changes a sprint counts and that the left-out ones are named by reason.
- docs/codebase-map.md: area 1's `tools/run_state.sh` entry names `queue_class` and the counted classes in place of `SPRINT_EXCEPTIONS`.
- CLAUDE.md: unchanged, its Sprints line already says T0 is exempt from a sprint's count and does not describe review-due's parsing.
- docs/architecture.md: unchanged, no layer or port is touched.
