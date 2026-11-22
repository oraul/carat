# Tasks

## 1. Workflow

- [x] 1.1 Remove the Scout phase, the area plan, `MAX_AREAS`, `SCOUT_AREA`, `SCOUT_PLAN`, `PACK_CURRENT`, `scoutTargets`, `scoutPrompt`, `unreadLine`, `PACK`, the `scout` and `areas` caps and profiles, and the `packs` and `areas` arguments from `.claude/workflows/deliver-change.js`; proved by "workflow: a delivery starts no scout" in `tools/tools_test.sh`
- [x] 1.2 Give the implement start the fixed `LOCATIONS` line (plan notes, else the queue entry or the brief), and ask the planner's prompt for them; proved by "workflow: the implement start takes its locations from the plan notes, the queue entry, or the brief", "workflow: the implement start carries the locations line", and "workflow: the planner prompt asks for the locations the change edits"

## 2. Agents and guard cases

- [x] 2.1 Delete `.claude/agents/scout.md`; update `.claude/agents/contributor.md`, `.claude/agents/planner.md`, `.claude/commands/deliver.md`, and `docs/contributor-notes.md` to the locations; proved by "workflow: a delivery starts no scout" (the agent file is gone) and `make docs-lint`
- [x] 2.2 Re-point the `read` profile guard cases of `tools/tools_test.sh` from `tmp/scout` to `build/plan`, drop the scout's caps, calibration, helper, and agent-file cases, and count nine guarded hook lines; proved by `make tools-test`
- [x] 2.3 Add `.claude/agents/scout.md` to `RETIRED` in `tools/docs_lint.sh`, which backlog entries may still name; proved by "docs_lint: a backlog file may name the retired queue, history, backlog file, and scout agent file"

## 3. Docs

- [x] 3.1 Drop the scout from `CLAUDE.md` (phases, the `scout` line), `README.md` (the pipeline's scout step, the mechanical agents), and `docs/goals.md` (the mechanical starts), and the `tmp/` comment of `tools/run_state.sh`; checked by `make docs-lint` and `make gates`
- [x] 3.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`

## Quality review

- [x] 4.1 The comment of `tools/run_state.sh` on `tmp/` named scouts the change removed; fixed in place
- [x] 4.2 A run state restored from before the change may carry `metric.calib.scout`, which `restoreCalibration` keeps and the metric line repeats though no start uses it; recorded in `docs/findings/scout-drop.md`: harmless recorded data, and filtering kinds needs new code beyond the brief
