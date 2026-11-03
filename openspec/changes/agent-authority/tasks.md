# Tasks

## 1. Run state and gates

- [x] 1.1 In `tools/run_state.sh`, refuse `set` of `review.*`, `phase.*`, and `stage.*`, validate `phase` names and `review` kinds, take an optional commit for both, and drop `report` from `PHASES`; verify with the run state cases in `tools/tools_test.sh` (`make tools-test`).
- [x] 1.2 Add the `records` gate to `tools/gates.sh` and its `merge` group; verify with the gate cases in `tools/tools_test.sh`.

## 2. Guard

- [x] 2.1 Add `tools/agent_guard.sh` with the read, contributor, and merger profiles; verify with the guard cases in `tools/tools_test.sh`.
- [x] 2.2 Add the guard hook to every agent under `.claude/agents/`, the contributor's `tools:` list, and the `gh pr merge` deny rule in `.claude/settings.json`; verify by reading each frontmatter against the design and `make docs-lint`.

## 3. Workflows and agents

- [x] 3.1 Record phases and reviews from `.claude/workflows/deliver-change.js` through `flush()` and pass `RECORDS` to the merger; record the periodic reviews from `.claude/workflows/periodic-review.js`; verify with `node --check` on both.
- [x] 3.2 Remove the `phase` and `review` records from the nine agents, point the merger at the workflow's gate line, and update `.claude/commands/review.md`; verify by reading each against the workflows and `make docs-lint`.

## 4. Docs

- [ ] 4.1 Update `CLAUDE.md`, `README.md`, the code map area 1 and its delivered changes, and remove the three fixed `docs/backlog.md` entries, adding the one for the `records` notice; verify with `make lint`, `make docs-lint`, and `make gates`.
