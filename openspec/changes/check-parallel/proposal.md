# Proposal

## Why

`sh tools/run_state.sh check CHANGE` runs the nine fast stages one after another: measured on the lane machine, docs-lint 6 s, dev-build 63 s, test-build 149 s, test-run 45 s, diagnose 184 s, bench-budget 63 s, metrics 16 s, tools-test 87 s, and gates 1 s, about 614 s of stage time and about 10.5 minutes of wall time with the clone. Most of the stages read nothing another stage writes, so the checker waits for work that could run beside the stage before it. The user, shown the stages running one after another, asked for them to run in parallel.

## What Changes

- The check runner starts the stages that need nothing still pending at once, at most `CHECK_JOBS` at a time (default 3), and keeps the order the stages really need (`STAGE_AFTER` in `tools/run_state.sh`): test-run only after test-build (its runner) and dev-build (the smoke test's binary) passed, metrics only after dev-build, test-build, and bench-budget (the reports and the binary it measures). metrics also runs alone (`STAGE_ALONE`), so its time per key is not measured beside a compiler. docs-lint, gates, diagnose, and tools-test are free.
- The stages left after the skip, carry, scope, and compile checks, which still run first and in order, are queued in `make stages` order; a free slot takes the first queued stage that is ready.
- Each stage keeps its own log in `build/stages/CHANGE/NAME.log` ending in its `EXIT n`, `KILLED:`, or `SUPERSEDED:` line, its `stage.NAME` record (`running`, then status, seconds, commit, time), and its exit status. Only the runner writes the run state and the compile records (`build/pipeline/compiled`); a stage's job writes only its log and its exit status, in the check clone, so concurrent stages never race on the run state's temporary file.
- A stage that does not pass ends the check: the runner stops the stages still running, records each as killed with a `KILLED:` line naming the stage that failed, prints the last lines of the failing stage's log, and prints its verdict line naming that stage and its log, as before.
- A signal or a superseding check stops and records every running stage, not only one, and a runner killed past its trap has every stage it left `running` recorded killed by the next check.
- `make check` and `make check-stage S=NAME` are unchanged; `tools/run_state.sh stage` runs one stage as before.
- Tests in `tools/tools_test.sh`: two free stages overlapping in time, test-run starting only after test-build passed, a failing stage failing the check with its own log while its sibling is recorded killed, every stage line recorded, `CHECK_JOBS=1` running the stages one at a time, and a killed check recording each running stage.

`CHECK_JOBS` defaults to 3: from the measured seconds the stage order needs gives a floor near 230 s at 3 jobs (the test-build and test-run chain, diagnose, then metrics alone) against near 350 s at 2, and two lanes checking at once run six stages on the machine's 4 CPUs, which a larger default would only crowd further.

The compile cache: dev-build, test-build, and bench-budget compile with `--incremental` into the one `build/spinel-cache` of the check clone. Spinel stores each cached object by writing a file named with its process id and renaming it over the entry (`tmp/.spinel/src/unit_cache.c`, the store function), so a reader sees no object or a whole one and two compilers storing the same entry leave one whole copy: the shared cache is safe under concurrent writers, and the agent guard's `SPINEL_CACHE_DIR` rule stays as it is. Every other build path is the stage's own (`build/dev`, `build/test`, `build/bench`, `build/diagnose`, `build/metrics`), and the helpers they call (`tools/spinel_warnings.sh`, `tools/analysis_budget.sh`) write a temporary file from `mktemp` or the stage's own path.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the pipeline's tooling only, no editor behavior (`skip_specs: true`).

## Impact

- `tools/run_state.sh`: `check_stages` becomes a scheduler; `run_stage` is split so the scheduler and the `stage` command share the end of a stage; `check_signalled` and `check_lost` handle several running stages.
- `tools/tools_test.sh`: the new cases; the stubs that end the runner find it by its pid file, since a stage's parent is now its job, not the runner.
- `Makefile`: the comment of `stages` says how the check runs them.
- README.md: changed, the checker paragraph says the stages run at once in the order they need.
- CLAUDE.md: unchanged, its `check CHANGE` entry ("runs the stages detached") stays true and the file is at its byte budget; the Makefile help, the script header, and `.claude/agents/checker.md` name `CHECK_JOBS`.
- docs/architecture.md: unchanged, it does not describe how the checker runs its stages.
- docs/codebase-map.md: changed, the Build and CI flow says the stages run at once; no file is added, moved, or removed.
- `.claude/agents/checker.md`: changed, its step 1 says the stages run at once and a failure stops the others.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action changes.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1, a user request) delivered as Sprint 13's user-approved exception.

## Out of scope

- CI (`.github/workflows/`), which runs its own jobs.
- `make check`, which keeps running `CHECK_STAGES` in order under a serial make.
- The run state's other writers: a `run_state.sh set` from another process while a check runs could still race with the runner's write, as before this change.
- `build/pipeline/compiled`, shared by every change: two lanes' runners can still write it at the same moment, as before this change.

Minor assumptions: a failing stage stops its running siblings rather than letting them finish, so the verdict comes at once; the excerpt is the failing log's last 20 lines; metrics runs alone, a 16 s cost, so its time figures stay comparable with main's.

## Results

Filled in after the real check of this change (task 4.1).
