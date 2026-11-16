# Tasks

## 1. Workflow

- [x] 1.1 Add `locations` to `SCOUT_PLAN.needed` and the location rule (no area for a path the map places in none) to the area-plan prompt in `.claude/workflows/deliver-change.js`; proved by "workflow: the area plan asks for each area's locations" in `tools/tools_test.sh`
- [x] 1.2 Add `scoutTargets` (no scout for an area without locations, the `MAX_AREAS` cut) and use it in the Scout phase; proved by "workflow: an area without locations starts no scout", "workflow: a plan of no area starts no scout", "workflow: no scout start without a needed area", "workflow: the areas beyond the room are cut"
- [x] 1.3 Pass the locations in the scout prompt and measure the area plan under `areas`; proved by "workflow: the scout prompt carries the locations" and "workflow: the area plan is measured apart from the scouts"
- [x] 1.4 Judge a pack current only when its `Locations:` line lists every location of the area (`PACK_CURRENT` in the area-plan prompt); proved by "workflow: a pack is current only when its Locations: cover the area's" and "workflow: the area plan applies the pack currency rule"

## 2. Scout agent

- [x] 2.1 Rewrite steps 4 to 7 of `.claude/agents/scout.md` to read only what the locations need, fix step 8's Rules line wording, and add the `Tool calls:` header line returned as `tool_calls`; proved by "scout: the steps read only the locations", "scout: step 8 copies the Rules line whatever it names", and "scout: the pack records its tool calls" in `tools/tools_test.sh`
- [x] 2.2 Reuse a pack in step 3 only when its `Locations:` line lists every given location; proved by "scout: a pack is reused only when it lists every given location"

## 3. Docs

- [x] 3.1 Update the README pipeline section's scout step (CLAUDE.md unchanged, the proposal says why); checked by `make docs-lint` and `make gates`
- [x] 3.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
