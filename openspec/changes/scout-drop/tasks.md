# Tasks

## 1. Workflow

- [ ] 1.1 Remove the Scout phase, the area plan, `MAX_AREAS`, `SCOUT_AREA`, `SCOUT_PLAN`, `PACK_CURRENT`, `scoutTargets`, `scoutPrompt`, `unreadLine`, `PACK`, the `scout` and `areas` caps and profiles, and the `packs` and `areas` arguments from `.claude/workflows/deliver-change.js`; proved by "workflow: a delivery starts no scout" in `tools/tools_test.sh`
- [ ] 1.2 Give the implement start the fixed `LOCATIONS` line (plan notes, else the queue entry or the brief); proved by "workflow: the implement start takes its locations from the plan notes, the queue entry, or the brief"

## 2. Agents and guard cases

- [ ] 2.1 Delete `.claude/agents/scout.md`; update `.claude/agents/contributor.md`, `.claude/agents/planner.md`, `.claude/commands/deliver.md`, and `docs/contributor-notes.md` to the locations; proved by "workflow: a delivery starts no scout" (the agent file is gone) and `make docs-lint`
- [ ] 2.2 Re-point the `read` profile guard cases of `tools/tools_test.sh` from `tmp/scout` to `build/plan`, and drop the scout's caps, calibration, helper, and agent-file cases; proved by `make tools-test`

## 3. Docs

- [ ] 3.1 Drop the scout from `CLAUDE.md` (phases, the `scout` line), `README.md` (the pipeline's scout step, the mechanical agents), and `docs/goals.md` (the mechanical starts); checked by `make docs-lint` and `make gates`
- [ ] 3.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
