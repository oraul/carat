# Tasks

## 1. Run state

- [x] 1.1 Key the sprint size on the sprint number in `tools/run_state.sh` (`SPRINT_SIZE=6`, `SPRINT_SIZE_FROM=17`, `SPRINT_SIZE_BEFORE=5`, `sprint_size` set by `sprint_state`, read by `review_due`, `sprint_row`, and `groom`); proved by "review-due is due at sprint-16's fifth counted merge", "review-due is not due at sprint-17's fifth counted merge", "review-due is due at sprint-17's sixth counted merge", "groom refuses sprint-17 at five history rows", and "the groomed sprint-17 row takes six changes" in `tools/tools_test.sh`
- [x] 1.2 Make `PICK_BATCHES` 3 in `tools/run_state.sh`; proved by "backlog-pick draws three batches, the sprint's three backlog items" in `tools/tools_test.sh`

## 2. Docs lint

- [x] 2.1 Cap the backlog lane's sprint at 3 items in `tools/docs_lint.sh`; proved by "docs-lint refuses a backlog sprint of 4 items" and "docs-lint accepts a backlog sprint of 3 items" in `tools/tools_test.sh`

## 3. Agents and docs

- [x] 3.1 Say 6 (3 + 3) from sprint-17 in `.claude/agents/planner.md`, `.claude/agents/retrospective.md`, `.claude/commands/sprint.md`, `.claude/workflows/sprint-planning.js`, and the comment of `.claude/workflows/deliver-change.js`; proved by the planner text check of `tools/tools_test.sh` naming "3 backlog items, the first three batches"
- [x] 3.2 Record the user's decision of 2026-11-17, for now, in `docs/goals.md`, and update `CLAUDE.md`, `README.md`, and `docs/codebase-map.md` (docs only, no test; `make docs-lint` and `make gates`)

## 4. Checks

- [ ] 4.1 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
