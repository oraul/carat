# Design

## Context

The Scout phase of `.claude/workflows/deliver-change.js` starts one area-plan agent (kind `areas`, fixed cap 10) that returns `current` packs and `needed` areas with a question, then one scout per needed area, at most `MAX_AREAS`, both measured under the usage key `scout`. Nothing in code decides whether a change's files are in a map area: the area plan does. The scout (`.claude/agents/scout.md`) reads the whole area's section, its files' entry points, callers, tests, and designs (steps 4 to 7) for its question, and returns `tool_calls`, which no pack line records.

## Goals / Non-Goals

**Goals:**

- A scout reads only what the change's edited locations need.
- No scout starts for a change whose files are in no map area.
- The recorded scout calls are the scouts' own, comparable with the packs' counts.
- Step 8 says what the map's Rules lines are.

**Non-Goals:**

- Changing caps, tiers, `MAX_AREAS`, or the pack's sections.

## Decisions

- Locations travel with each needed area. `SCOUT_PLAN.needed` items require `locations`, a list of `path` or `path:line` of existing code the change edits in that area, each a path the area's section of the map names, itself or by its directory; the plan prompt says a path the map places in no area (a root file such as `LICENSE`) belongs to no area. Alternative: map paths to areas in the workflow; the workflow has no file reading, and the map names files in prose, so the plan agent keeps the lookup, now with a checkable output.
- `scoutTargets(plan, max)`, a pure function, returns `{ current, needed, unplaced, beyond }`: needed areas without a location go to `unplaced` and start no scout (a note names them), the rest are cut at the room left by current packs. A null plan gives empty lists. Being pure, `tools/tools_test.sh` runs it with `js`.
- The scout prompt gives `Locations:` and says to read only what they need; `scout.md` steps 4 to 7 follow the locations (the area's lines naming them, each file only at the location, callers and tests of the methods at the locations, a design only for the question), with the question's entry points standing in when a scout is run by hand without locations.
- The area plan is measured under `areas`, so `phase.scout=TOKENS/CALLS` sums only the scout starts, whose `tool_calls` each pack header now records (`Tool calls: N`). The comparison of tokens with the brief's figures sums `phase.scout` and `phase.areas`; the `tokens` command still keys both by the workflow phase `Scout`.
- A pack is current only when its `Locations:` line lists every location the change edits in its area, besides the commit check: packs are bounded to their locations, so a narrow pack an earlier change left in the area holds no facts about other files of it. The area-plan prompt states it through `PACK_CURRENT` and `scout.md` step 3 applies the same rule to the locations it was given.
- Step 8 copies the Rules line as written, whether it names sections or states the rule itself, and still opens neither `CLAUDE.md` nor `docs/architecture.md`.

## Risks / Trade-offs

- A plan that names a location the map does not place still starts a scout; the prompt's rule and the required list make the lapse visible in the run notes, and the acceptance (under 2% for such a change) is measured on the next runs.
- Splitting `phase.areas` from `phase.scout` changes what the history's `scout` phase means from this run on; the design and the README name the split so the figures stay comparable.
