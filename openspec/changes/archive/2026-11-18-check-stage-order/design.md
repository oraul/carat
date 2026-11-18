# Design

## Context

`stages_start` in `tools/run_state.sh` dispatches queued stages in queue order while fewer than `CHECK_JOBS` run; a stage named first in a `STAGE_AFTER` pair waits while the pair's second stage is queued or running, and a prerequisite in neither (skipped, carried, scoped, compiled, or not in the stage list) imposes no wait. gates had no pair, so with a free slot it started beside test-build.

## Decisions

- One pair, `gates:test-build`, in `STAGE_AFTER`, the existing mechanism; no new scheduling rule. A skipped test-build (compiled the same code with its outputs unchanged, or passed at HEAD) leaves its runner in place, so gates needs no wait then, which the existing rule already gives.
- Readers of test-build's outputs, by grep over `tools/` and the Makefile: test-run (the runner, already paired), metrics (`build/test/run_all.timing`, already paired), gates (`gate_snapshots`, `build/test/run_all`, now paired). diagnose compiles `test/runner/run_all.rb` from source and stays free.
- Test: the existing `par_check` stub runs any stage name, so a check of `gates test-build docs-lint` queues gates first; without the pair gates starts first, with it gates starts only after test-build's end, which `order` proves.

## Risks

- A longer check when gates would have finished beside test-build: small, as gates takes seconds and test-build is on the critical path to test-run anyway.
