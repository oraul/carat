# Design

## Context

The Scout phase of `.claude/workflows/deliver-change.js` starts an area-plan agent (kind `areas`, fixed cap 10), which lists the map areas a change edits with their locations and the current packs under `tmp/scout/`, then one scout (`.claude/agents/scout.md`, kind `scout`, cap 30 at medium) per needed area, at most `MAX_AREAS`. The implement prompt then carries `Scout packs: ...` and the locations no pack covers (`unreadLine`). The contributor reads the packs first (`contributor.md`, `docs/contributor-notes.md`, Context). The retros show the contributor redoing those facts while the planner's notes, the queue entry, or the brief already name the paths and lines.

## Goals / Non-Goals

**Goals:**

- No delivery starts an area plan or a scout; their caps, calibration profiles, schemas, and helpers go.
- The contributor gets its locations from the plan notes, else the queue entry or the brief, stated in its implement prompt.
- The guard cases that exercised the `read` profile through the scout's directory keep exercising it through the planner's `build/plan`.

**Non-Goals:**

- Changing `tools/agent_guard.sh`, any other phase's cap or tier, or the history's recorded figures.

## Decisions

- One fixed line, `const LOCATIONS`, replaces the packs and unread text of the implement prompt, so a test reads it with the `js` helper and a grep proves the implement call starts with it. The plan notes come right after it, as before. Alternative: let the workflow derive locations; it reads no file and the plan notes, the queue entry, or the brief already carry them.
- The `packs` and `areas` start arguments go with the phase: `startInput` keeps only the listed keys, so an old caller passing them is ignored, never failed.
- `scout` and `areas` leave `CALL_CAPS`, `FIXED_CAPS`, and `CALIBRATION`: no start uses them, and the tools-test loops that require a cap and a profile for every started kind still pass. `restoreCalibration` keeps reading any `metric.calib.KIND`, so a restored older run state carrying `calib.scout` is harmless.
- The `read` profile guard cases move from `tmp/scout` to `build/plan`, the directory the planner's hook passes, the same forms and refusals asserted; the three dry runs of the scout's steps become the same commands under the `read` profile with `build/plan`, which the planner can run.
- `.claude/agents/scout.md` is deleted, by the user's decision; its tools-test cases (steps 3, 4, 8, the Tool calls line, its maxTurns, its calibration pair) go with it, and the rules-check agent list drops it.
- The planner's step 7 asks for the locations the change edits among its notes, the first source the contributor's line names.

## Risks / Trade-offs

- A change whose brief and plan name no location leaves the contributor to find them through the map itself, the work a scout did; the keep-or-revert decision over the next 5 rows of the history measures it (implement calls and tokens against the scout plus implement figures before).
- The history's `scout` and `areas` phase columns stop growing; earlier rows keep them as recorded.
