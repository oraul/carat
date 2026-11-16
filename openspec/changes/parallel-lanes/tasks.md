# Tasks

## 1. Run state

- [x] 1.1 `tools/run_state.sh`: `lane_of` for an unmerged change, `plan-apply CHANGE`, the lane-only `history CHANGE`, `groom` applying only for `sprint-N-records`, `plan-needed` for the records change, the header; proved by the `tools/tools_test.sh` cases "plan-apply copies only its lane's queue", "two lanes' plans", "history appends only its lane's rows", "groom refuses a delivery's change", "groom applies the sprint plan" (now run as `sprint-2-records`).
- [x] 1.2 `tools/agent_guard.sh`: the contributor runs `plan-apply`; proved by "guard: the contributor applies its plan".

## 2. Workflows and agents

- [x] 2.1 `.claude/workflows/deliver-change.js`: the planner writes `build/plan/<change>/`; the package step runs `plan-apply` and `history`, never `groom`, and nothing for a records change; proved by the cases reading its prompts.
- [x] 2.2 `.claude/workflows/sprint-planning.js`: the Records phase delivering `sprint-N-records`; proved by "sprint-planning delivers the sprint's records change".
- [x] 2.3 `.claude/agents/planner.md` and `contributor.md`: the plan directory and the package and records steps; proved by the agents cases.

## 3. Docs and checks

- [x] 3.1 README.md and `docs/codebase-map.md` area 1; `make docs-lint`.
- [x] 3.2 `make tools-test` (seconds against main's), `make gates`, `make spec-validate`.
