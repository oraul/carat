# Proposal

## Why

Scouts spent 51,496 of 127,096 output tokens (40.5%) and 62 of 166 tool calls at #140, more than the implement phase's 30,295, while the packs counted 27 calls of their own; #134, #135, and #137 spent 32.1%, 18.7%, and 20.9%, #137 on a root `LICENSE` that is in no map area, against 472 and 1,397 at #130 and #133. A scout is given an area and a question and its steps 4 to 7 (`.claude/agents/scout.md`) read the area's files, callers, tests, and designs wide; the area plan (`.claude/workflows/deliver-change.js`, the Scout phase) may name an area for a file the map does not place, and its own calls and tokens are recorded under the scouts' key, so the recorded calls cannot be compared with the packs'. Step 8 also says every Rules line names the sections, which several map Rules lines do not.

## What Changes

- The area plan gives each area it still needs a pack for the locations the change edits there (`path` or `path:line`, each a path the area's section of `docs/codebase-map.md` names, itself or by its directory); a file the map places in no area, such as a root `LICENSE`, belongs to no area, so a change editing only such files lists none.
- A pure helper of the workflow, `scoutTargets`, starts no scout for an area given without a location, notes it, and keeps the `MAX_AREAS` cut; the scout's prompt carries the locations.
- The area plan is measured under its own key, `areas` (its calibration kind and fixed cap already are), so `phase.scout` holds only the scouts' starts, the figure compared with the packs' own counts; the scouts' share the acceptance measures is `phase.scout` plus `phase.areas`, the same total the brief's figures counted.
- `.claude/agents/scout.md` reads only what the locations need: the map lines naming them, each file only at its locations, callers and tests of the methods there, a design only when the question asks for one; step 8 copies the Rules line as written, whether or not it names sections; the pack header records the scout's tool calls, the number it returns.
- Cases in `tools/tools_test.sh` prove an area without locations starts no scout, a plan of no area starts none, the `MAX_AREAS` cut, the scout prompt's locations, and the plan measured under `areas`.
- The README pipeline section says the scouts read the edited locations, none starts for a change in no map area, and the area plan is recorded apart.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`, `tools/tools_test.sh`.
- README.md: changed, the pipeline section's scout step.
- CLAUDE.md: unchanged, its `scout` line (one map area at the current commit into a pack of facts) still holds; the locations and the no-area rule live in `.claude/agents/scout.md`, the workflow, and the README, and the file is 2 bytes under its budget.
- docs/architecture.md: unchanged, it does not describe the scouts' reading.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline retrospective fix (T1) of sprint 8.

Backlog headings this change covers, from its queue entry: "## The scout's step 8 says every Rules line names sections".

Minor assumptions: the scout's call cap (30 at medium) and the pack's length limit stay as they are, the narrower reading being the fix the brief names; the acceptance figures are measured on the next runs, not by this change.

## Out of scope

- The scout's call cap, the pack length, the number of areas, and the scout's model tier.
- The other sprint 8 items and any queue reordering.
