# Tasks

## 1. Continued starts

- [x] 1.1 `.claude/workflows/deliver-change.js`: `CONTINUES`, `continuation`, `workLeft`, the `partial` status and `remaining` of the contributor's result, and `contributor()` continuing a partial or empty start. Tested by "workflow: a capped contributor start is continued with what it left", "workflow: a contributor start with no result is continued", "workflow: a contributor with a question stops", and "workflow: a start still unfinished after the continuations stops".
- [x] 1.2 `.claude/workflows/deliver-change.js`: `not_reviewed` of the diff reviews, `reviewLeft`, `combineReviews`, and `reviews()` continuing a review; a security review with anything left stops the run. Tested by "workflow: a capped review is continued over the files it left", "workflow: a security review that did not run is continued whole", and "workflow: a continued review keeps the findings of both starts".
- [x] 1.3 `.claude/agents/contributor.md`, `quality-reviewer.md`, `security-reviewer.md`: return `partial` and `remaining`, or `not_reviewed`, at the cap.

## 2. Periodic quality by area

- [x] 2.1 `.claude/workflows/periodic-review.js`: `MAP_AREAS`, `QUALITY_SLICES`, `areaSlices`, the quality starts by slice with their worktrees, one continuation of the areas left, and `covered=N/18` in the record. Tested by "periodic: the map has MAP_AREAS areas", "periodic: the quality slices cover every area once", "periodic: the areas left are kept to the start's slice", and the existing partial and cap cases.
- [x] 2.2 `.claude/agents/quality-reviewer.md`: the periodic mode reads the areas and the worktree the input names.

## 3. The merger's head and cap

- [x] 3.1 `tools/run_state.sh`: `push` records the full sha. Tested by "run_state: push records the full sha as pushed".
- [x] 3.2 `.claude/workflows/deliver-change.js`: `pushed` in the work result, `pushedHead`, and the merge prompt with the full sha. Tested by "workflow: the merger gets the full pushed sha" and "workflow: a pushed sha other than the reported head is refused".
- [x] 3.3 `.claude/agents/merger.md` and `FIXED_CAPS.merger`: the full sha in steps 1 and 5, the counted branch deletion, the cap of 12, and `maxTurns` 27. Tested by "caps: the merger's first green fits its cap" and "caps: the merger file's maxTurns is its ceiling".

## 4. Docs and bookkeeping

- [ ] 4.1 `README.md` (the continued starts, the periodic quality slices, the merger's cap and full sha) and `docs/codebase-map.md` area 1 (the `tools/tools_test.sh` entry with the call caps and the workflow helpers); `CLAUDE.md` stays true as written.
- [ ] 4.2 `docs/backlog.md`: the six planner entries added, the search-options entry removed, the CLAUDE.md-per-start entry pointed at `docs-index`, the refused-backup evidence added, and the three merger entries removed.
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`, and `openspec validate partial-results --strict --no-interactive`.
