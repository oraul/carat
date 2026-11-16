# Tasks

## 1. Lanes in the run state

- [x] 1.1 Add `history_rows`, `lane_rows`, `lane_of`, `queue_at`, and the `lane` command to `tools/run_state.sh`; history appends to the lane file; status, bench, has_row, sprint_state, merged_of, sprint_row, groom, and merged_since read the lanes; proved by "run_state: history appends a backlog change's row to the backlog lane" and the existing history and review-due cases in `tools/tools_test.sh`
- [x] 1.2 Make `estimate_of`, `exception_item`, and `plan_needed` read the lane queues, `exception_item` the merged commit and the exception line too; proved by "run_state: review-due leaves out a change its merged queue's exception line names" and the existing estimate and plan-needed cases
- [x] 1.3 Write late findings to `docs/findings/`, fold the findings files into the backlog in `groom`, read them in `backlog-dups`; proved by "run_state: groom folds two changes' findings into the backlog" and "run_state: history writes the late findings to the change's findings file"

## 2. Lint, gates, migration

- [x] 2.1 Update `tools/docs_lint.sh` (the shared lane budget, lane sprint shapes, the retired paths) and `tools/rules.sh` RECORDS_RE; checked by `make docs-lint` and the scope cases
- [x] 2.2 Move the rows of `docs/metrics.tsv` and the items of `docs/queue.md` into the lane files, none lost, and remove the old files

## 3. Agents, workflow, docs

- [x] 3.1 Update the planner, contributor (findings file, conflict rules), checker, quality reviewer, retrospective, the commands, and `.claude/workflows/deliver-change.js`
- [x] 3.2 Update CLAUDE.md, README.md, docs/goals.md, docs/codebase-map.md, `tools/gates.sh` and `tools/ci_wait.sh` comments
- [ ] 3.3 Run `make tools-test` (seconds compared with main), `make docs-lint`, `make gates`, `make spec-validate`
