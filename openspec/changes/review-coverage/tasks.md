# Tasks

## 1. Planner trigger

- [ ] 1.1 Add `merged_since` to `tools/run_state.sh` and make `plan_needed` print `needed:` for a `review-*` or `sprint-*` run state whose periodic security review failed with no merge after its commit; proved by "run_state: plan-needed names a failing periodic security review no merge followed" and "run_state: plan-needed leaves a failing periodic security review a later merge followed" in `tools/tools_test.sh`

## 2. Sprint count

- [ ] 2.1 Add `SPRINT_EXCEPTIONS` to `tools/run_state.sh`, cap the exceptions in `sprint_state` with a plain `if` that stops at the cap; proved by "run_state: review-due counts a change beyond the sprint past the sprint's one exception" in `tools/tools_test.sh`
- [ ] 2.2 End `sprint_row` at the fifth counted change; proved by "run_state: the groomed sprint row ends at the fifth counted change, a later exception left to the next sprint" in `tools/tools_test.sh`

## 3. Docs

- [ ] 3.1 Update the run_state.sh header and comments, the comment above `planSkipped`'s plan phase in `.claude/workflows/deliver-change.js`, the README pipeline section, and the map's `tools/run_state.sh` entry; checked by `make docs-lint` and `make gates`
- [ ] 3.2 Run `make tools-test` (seconds compared with the run before the change), `make docs-lint`, `make gates`, and `make spec-validate`
