# Tasks

## 1. Plan

- [ ] 1.1 Add `planSkipped` to `.claude/workflows/deliver-change.js` and skip the Plan phase on `not needed:` whatever the brief; proved by "workflow: a brief fixing the order skips the planner" in `tools/tools_test.sh`

## 2. History

- [ ] 2.1 Add `merged_on_main` to `tools/run_state.sh`, use it in `pending_list`, and report a never-merged run in `append_history`; proved by "run_state: history keeps a never-merged run out" and "run_state: pending skips a run whose merged commit is not on main" in `tools/tools_test.sh`

## 3. Sprint count

- [ ] 3.1 Add `EXCEPTION_MARK`, `merged_of`, and `exception_item` to `tools/run_state.sh`; leave marked changes out of `sprint_count`, name them on review-due's not-due line, and count the same way in `sprint_row` and `groom`; proved by "run_state: review-due leaves a user-approved exception out of the count" and "run_state: review-due is due at the fifth counted merge beside an exception" in `tools/tools_test.sh`

## 4. Docs

- [ ] 4.1 Update the README pipeline section, CLAUDE.md's Sprints line, and the map's `tools/run_state.sh` entry; checked by `make docs-lint` and `make gates`
- [ ] 4.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
