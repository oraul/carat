# Tasks

## 1. Run state

- [ ] 1.1 `tools/run_state.sh`: `report` in `PHASES`; tested by the `tools/tools_test.sh` case "run_state: phase accepts report".
- [ ] 1.2 `tools/run_state.sh check`: carry a passed stage outside `TEST_STAGES` when only `test/` and unchecked paths changed since; tested by the cases "check carries a stage after a test-only commit", "check reruns the test stages", "a carried stage names its commit", and "check reruns every stage after a change outside test/".
- [ ] 1.3 `tools/run_state.sh bench`: import the measurement, compare with the last history row through `make metrics-compare`, exit 0 when allocations and rounds equal it; tested by the cases "bench needs the metrics stage at HEAD", "bench passes the same figures", "bench writes the last row as a base", and "bench names a differing figure".
- [ ] 1.4 `tools/run_state.sh history`: first passes from `metric.first.*`, an older `metric.first_pass`, or the `stage.*`, `review.*`, and `ci` lines; phases and totals from `metric.phase.*`; tested by the cases "history derives the first passes", "history groups the phase figures", and "history sums the phase figures", beside the existing row case.

## 2. Guard

- [ ] 2.1 `tools/agent_guard.sh`: the contributor may write and name `build/pipeline/<change>.body.md`; both profiles refuse the name followed by `/`; tested by the cases "contributor writes the body file", "contributor allows the body gate", "merger refuses a path through the body file", and "contributor refuses a path through the body file".

## 3. Workflow and agents

- [ ] 3.1 `.claude/workflows/deliver-change.js`: scouts capped at three edited areas, plan notes to the contributor; figures queued as they happen and seeded on resume; required `tool_calls`; the bench review from the checker's `bench_same`; the quality prompt with the prior findings; one merger call loop for CI and the merge; the report phase; the four flushes. Checked by `node --check` and a dry read of each branch.
- [ ] 3.2 Agents: remove `ci-watcher.md`; `merger.md` waits for CI with backoff and merges from the body file; `checker.md` runs `run_state.sh bench`; `benchmark.md` and `quality-reviewer.md` take the new inputs; `planner.md` returns plan notes; `retrospective.md` and `reporter.md` read the stored figures; `contributor.md` writes the body file.

## 4. Docs

- [ ] 4.1 `CLAUDE.md` (Agents), `README.md` (How carat is built with AI), `docs/codebase-map.md` (area 1 and the delivered-changes line), `Makefile` and `.github/workflows/ci.yml` comments, `tools/agent_guard.sh` header; `docs/backlog.md` loses the two entries this change settles. Checked by `make docs-lint`, `make tools-test`, and `make gates`.
