# Tasks

## 1. Estimate

- [ ] 1.1 `tools/run_state.sh`: `estimate_of` reads `metric.estimate` first, then the queue item at the squash commit's parent; `budget`'s no-estimate line names both. Tested by the `tools/tools_test.sh` cases "run_state: budget reads the stored estimate of a change with no queue item", "run_state: the stored estimate wins over the queue item", "run_state: budget reads the stored estimate before the merge", and "run_state: history records the stored estimate".

## 2. CI wait

- [ ] 2.1 `tools/ci_wait.sh`: a foreground wait of 1 to 540 seconds. Tested by the cases "ci_wait: waits the given seconds", "ci_wait: refuses zero", "ci_wait: refuses more than 540", and "ci_wait: refuses a value that is not a whole number".
- [ ] 2.2 `.claude/agents/merger.md`: the schedule through `ci_wait.sh` until 30 minutes, `waited` in the result, the metric line first. Checked by `make docs-lint` (agent budget).

## 3. Workflow

- [ ] 3.1 `.claude/workflows/deliver-change.js`: `metricLine()` replaces `figure()`; `flush()` starts an agent only for queued records; no flush after the package step or the merge; the package step resumes from `pushed` and `pr`; the merger and the retrospective run the metric line first; `qualityAdvisory` kept, seeded, and handed to the package step; `PLAN.estimate` stored; `MERGE.waited` noted. Checked by `node --check`.
- [ ] 3.2 `.claude/agents/quality-reviewer.md` (the `quality-advisory` notes), `planner.md` (the note kind and `estimate`), `retrospective.md` (the metric line first). Checked by `make docs-lint`.

## 4. Docs

- [ ] 4.1 `docs/codebase-map.md` area 1 (`tools/ci_wait.sh`, `estimate_of`), `README.md` (the merger's wait, the records, the estimate), and the header comments of `tools/run_state.sh` and the workflow. Checked by `make docs-lint`, `make tools-test`, and `make gates`.
