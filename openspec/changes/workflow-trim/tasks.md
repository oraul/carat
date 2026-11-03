# Tasks

## 1. Run state

- [x] 1.1 `tools/run_state.sh`: `report` in `PHASES`; tested by the `tools/tools_test.sh` case "run_state: phase accepts report".
- [x] 1.2 `tools/run_state.sh check`: carry a passed stage outside `TEST_STAGES` when only `test/` and unchecked paths changed since; tested by the cases "check carries a stage after a test-only commit", "check reruns the test stages", "check reruns diagnose, which reads the test runner, after a test-only commit", "check reruns docs-lint, which reads the docs and the test paths they name, after a test-only commit", "a carried stage names its commit", and "check reruns every stage after a change outside test/".
- [x] 1.3 `tools/run_state.sh bench`: import the measurement, compare with main's figures (the newest merged change without a history row, else the last row) through `make metrics-compare`, exit 0 when allocations and rounds equal them; tested by the cases "bench needs the metrics stage at HEAD", "bench passes the same figures", "bench compares through make metrics-compare", "bench writes the last row as a base", "bench records the measurement", "bench names a differing figure", "bench compares with the merged change that has no history row", "bench writes the pending change's figures as a base", "bench names a figure that differs from the pending change's", "bench does not compare with a pending change without figures", and "bench refuses a measurement of another commit".
- [x] 1.4 `tools/run_state.sh history`: first passes from `metric.first.*`, an older `metric.first_pass`, or the `stage.*`, `review.*`, and `ci` lines; phases and totals from `metric.phase.*`; tested by the cases "history derives the first passes", "history groups the phase figures", and "history sums the phase figures", beside the existing row case.

## 2. Guard

- [x] 2.1 `tools/agent_guard.sh`: the contributor may write and name `build/pipeline/<change>.body.md`; both profiles refuse the name followed by `/`; tested by the cases "contributor writes the body file", "contributor allows the body gate", "merger refuses a path through the body file", "contributor refuses a path through the body file", "contributor still refuses the run state file", and "read refuses a metrics override of the bench" (`METRICS_OUT` joins the overrides the guard refuses).

## 3. Workflow and agents

- [x] 3.1 `.claude/workflows/deliver-change.js`: scouts capped at three edited areas, plan notes to the contributor; figures queued as they happen and seeded on resume; required `tool_calls`; the bench review from the checker's `bench_same`; the quality prompt with the prior findings; one merger call loop for CI and the merge; the report phase; the four flushes. Checked by a dry run of the old and the new script with canned agent results (normal, a quality fix round, CI pending twice, and a resume): agent calls 24 to 18, 27 to 21, and a stall that now merges after two waits; record flushes 7 to 4; seeded figures carried.
- [x] 3.2 Agents: remove `ci-watcher.md`; `merger.md` waits for CI with backoff and merges from the body file; `checker.md` runs `run_state.sh bench`; `benchmark.md` and `quality-reviewer.md` take the new inputs; `planner.md` returns plan notes; `retrospective.md` and `reporter.md` read the stored figures; `contributor.md` writes the body file.

## 4. Docs

- [x] 4.1 `CLAUDE.md` (Agents), `README.md` (How carat is built with AI), `docs/codebase-map.md` (area 1 and the delivered-changes line), `Makefile` and `.github/workflows/ci.yml` comments, `tools/agent_guard.sh` header; `docs/backlog.md` loses the two entries this change settles. Checked by `make docs-lint`, `make tools-test`, and `make gates`.
