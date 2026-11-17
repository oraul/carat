# Tasks

## 1. Scheduler

- [x] 1.1 Split the end of `run_stage` into `stage_end` and add the job, `stage_launch`, in `tools/run_state.sh`; proved by "a failing stage keeps its exit status", "the stage log ends with its status", and "a stage records exit, time, and commit" in `tools/tools_test.sh` staying green
- [x] 1.2 Make `check_stages` queue the stages left after the skip rules and run them at once under `CHECK_JOBS`, in the order of `STAGE_AFTER` and `STAGE_ALONE`, only the runner writing the run state; proved by "check runs two free stages at once", "check starts test-run only after test-build passed", "check runs metrics alone", "check runs one stage at a time with CHECK_JOBS=1", "every stage of a parallel check is recorded", and "check refuses a CHECK_JOBS that is no number" in `tools/tools_test.sh`
- [x] 1.3 Stop and record the running stages on a failure, with the failing log's excerpt before the verdict; proved by "a failing stage fails a parallel check with its own log", "a failing stage's excerpt comes before the verdict", and "a sibling stopped by a failure is recorded killed" in `tools/tools_test.sh`

## 2. Signals

- [x] 2.1 Make `check_signalled` and `check_lost` record every running stage; proved by "a killed check records each running stage" and "a hard-killed check records each running stage" in `tools/tools_test.sh`, with the existing killed and superseded cases, their stubs finding the runner by its pid file

## 3. Docs

- [x] 3.1 Describe the parallel check in the Makefile's `stages` comment, README.md, `docs/codebase-map.md` area 1, and `.claude/agents/checker.md` (docs only, no test; `make docs-lint` and `make gates`)

## 4. Checks

- [ ] 4.1 Run one real `sh tools/run_state.sh check check-parallel` and record its wall time against the 10.5-minute sequential figure in the proposal's Results
- [ ] 4.2 `make gates`, `make spec-validate`, `make docs-lint`, and `make tools-test` pass
