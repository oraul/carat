# Proposal

## Why

The scouts cost a large share of a delivery while the contributor redoes their facts: 43,825 of 221,104 output tokens (19.8 percent) and 36 of 164 tool calls at `files-ex-lows` (retro note 2), 55,071 tokens and 23 calls at `sprint-close-lows` (retro note 2), and 14,768 tokens and 11 calls at `picker-speed`, whose plan already named every path with a line (retro note 3). The planner's notes, the queue entry, or the brief already give the locations a change edits, so the area plan and the scout starts add a pass the contributor repeats. By the user's decision of 2026-11-22 the scout is dropped and `.claude/agents/scout.md` deleted.

## What Changes

- `.claude/workflows/deliver-change.js` starts no area plan and no scout: the Scout phase, `MAX_AREAS`, `SCOUT_AREA`, `SCOUT_PLAN`, `PACK_CURRENT`, `scoutTargets`, `scoutPrompt`, `unreadLine`, `PACK`, the `scout` and `areas` entries of `CALL_CAPS`, `FIXED_CAPS`, and `CALIBRATION`, and the `packs` and `areas` start arguments are removed, so no `phase.scout`, `phase.areas`, `calib.scout`, or `calib.areas` figure is written from now on.
- The implement start's prompt carries one fixed line, `LOCATIONS`: the contributor takes the paths and lines the change edits from the plan notes, else from its queue entry or the brief; the planner's prompt asks for those locations, `path:line` each, among its notes.
- `.claude/agents/scout.md` is deleted.
- `.claude/agents/contributor.md` and `docs/contributor-notes.md` (Context) start from those locations instead of the scout packs under `tmp/scout/`; `.claude/agents/planner.md` drops its "never a scout"; `.claude/commands/deliver.md` no longer passes packs.
- `tools/tools_test.sh`: the guard cases of the `read` profile that used the scout's `tmp/scout` directory use the planner's `build/plan`; the scout's caps, calibration, `scoutTargets`, and `scout.md` cases are removed; new cases show a delivery starting no scout (no `scout` in the workflow, every started agent type an agent file, `scout.md` gone) and the implement start carrying the locations line.
- `tools/docs_lint.sh` adds `.claude/agents/scout.md` to `RETIRED`, the paths the backlog files may still name, as it does for the queue, history, and backlog file earlier changes retired, since backlog entries written before name the deleted file and no delivery edits the backlog; a tools-test case proves it.
- The comment of `tools/run_state.sh` on what `tmp/` holds no longer names scouts.
- `CLAUDE.md`, `README.md`, and `docs/goals.md` drop the scout from the phases, the agent list, and the mechanical starts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md` (deleted), `.claude/agents/contributor.md`, `.claude/agents/planner.md`, `.claude/commands/deliver.md`, `docs/contributor-notes.md`, `docs/goals.md`, `tools/tools_test.sh`, `tools/docs_lint.sh` (`RETIRED`), `tools/run_state.sh` (one comment).
- CLAUDE.md: changed, the Agents phases and the `scout` line.
- README.md: changed, the pipeline section's scout step and the list of mechanical agents.
- docs/architecture.md: unchanged, it does not describe the scouts.
- docs/codebase-map.md: unchanged, it maps no file under `.claude/` (the queue entry's "map row" does not exist); its two scout mentions are history lines of delivered changes.
- `tools/agent_guard.sh`: unchanged, its `read` profile takes the directory as an argument and the planner keeps using it with `build/plan`.
- `tools/rules.sh`: not edited.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline efficiency change (T1) by the user's request, the first Sprint 29 backlog item under the user-approved exception of 2026-11-22.

Backlog headings this change covers, from its queue entry: "### Scout packs whose facts the contributor redoes", "### The scout's pack is redone by the contributor (sprint-security retro note 7)", "### A scout runs when the plan already names every expected path with a line (picker-speed retro note 3)", "### A scout reads the half a delivery-time split moved out (sprint-close-lows retro note 2)".

Minor assumptions: the history fixtures of `tools/tools_test.sh` that hold `calib.scout=cheap/low` stay as recorded data, as do the scout words in `docs/metrics-*.tsv`, `docs/sprints.tsv`, and history lines; the `scout` word of the pipeline classifier in `tools/run_state.sh` stays so earlier rows keep their class; a run state restored from before this change may still carry `metric.calib.scout`, which `restoreCalibration` keeps as a recorded profile and no start uses. This run itself still starts the areas plan and scouts, since it runs the workflow as it is on `main`; the saving shows from the next delivery on.

## Out of scope

- The keep-or-revert decision over the next 5 rows, which the planner makes from the history after this change merges.
- Any other cap, tier, or phase; `tools/agent_guard.sh`; `tools/rules.sh`; the feature lane's files.
