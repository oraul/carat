# Tasks

## 1. Per-lane queue budgets

- [x] 1.1 `tools/docs_lint.sh`: replace `QUEUE_BUDGET` with `QUEUE_BUDGET_FEATURE` and `QUEUE_BUDGET_BACKLOG`; `own_lane` names the lane being checked; `check_queue` and `check_lane` check only that lane's queue against its own budget, both lanes on main, a detached head, and a records change.
- [x] 1.2 `tools/tools_test.sh`: each queue at its budget passes; one lane's queue over its budget fails only that lane's docs-lint (by `DOCS_LINT_LANE`, by the branch type, and by the queue naming the change); a full run names the over-budget file.

## 2. Fit before the push

- [x] 2.1 `tools/run_state.sh`: `queue_budget`, `queue_fit` in `plan-apply` (drop Decisions bullets from the last up, else refuse with the overage, the queue unchanged), and `queue_over` refusing a push whose lane queue at HEAD is over budget.
- [x] 2.2 `tools/tools_test.sh`: plan-apply trims an over-budget queue's Decisions bullets, refuses one that dropping them all cannot fit, and push refuses an over-budget lane queue.

## 3. Lane-local metrics

- [x] 3.1 `tools/run_state.sh`: `metrics_out` under `tmp/.lane-<change>/build/` when run from the main checkout with the lane present; `bench` passes `METRICS_OUT` to `make metrics-compare`. `.claude/agents/benchmark.md`: its make targets run in the lane.
- [x] 3.2 `tools/tools_test.sh`: a check's and bench's metrics files land under the lane, none in the main checkout's `build/metrics`.

## 4. An escaped check reruns

- [x] 4.1 `tools/run_state.sh`: an escape after every stage passed prints `check: stage none escaped`, rewrites the stage records the runner wrote as `escaped`, and clears their compile records.
- [x] 4.2 `.claude/workflows/deliver-change.js`: `checkVerdict` reads `escaped`, `RERUN_WORDS` takes it, so it reruns under `RERUNS` with no checker log start and no fix round.
- [x] 4.3 `tools/tools_test.sh`: the escaped verdict line, its stage records read as not passing and are not reused, and the workflow reruns it with no fix round.

## 5. Documents

- [x] 5.1 README.md, `.claude/agents/planner.md`, `.claude/agents/checker.md`, and `docs/codebase-map.md` name the per-lane budgets, the fit, the lane-local metrics, and the escaped verdict.

## 6. Checks

- [ ] 6.1 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`.

## 7. Quality review

- [x] 7.1 The script header of `tools/run_state.sh` still gave `build/metrics/current.tsv` as METRICS_OUT's only default and said an escape fails the check: name the lane default and the escaped verdict. Fixed.
- [x] 7.2 An escaped check also rewrites the derived passes it wrote (carried, scoped, compiled), which the next check derives again or runs: safe, recorded as a design note in `design.md`, no code change. Fixed in the design text.
