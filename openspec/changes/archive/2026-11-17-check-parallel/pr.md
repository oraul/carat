chore(tools): run the check stages in parallel

## Summary

The checker's `sh tools/run_state.sh check` now runs the independent fast stages at once, at most `CHECK_JOBS` at a time (default 3), in the order the stages really need, instead of one after another. The nine stages took about 10.5 minutes in sequence, the user asked for them to run in parallel, and the measured check now passes in 368 s.

---

## Changes

- Change the check runner into a scheduler that starts every ready stage up to `CHECK_JOBS`, holding test-run until test-build and dev-build passed and running metrics alone after the builds and bench-budget it reads, while docs-lint, gates, diagnose, and tools-test run free.
- Keep each stage's own log in build/stages, its `stage.NAME` record, and its exit status, with only the runner writing the run state and the compile records so concurrent stages never race on them.
- Change a failing stage to stop the stages still running, record each as killed naming the failed stage, and fail the check with the failing stage's log excerpt and verdict line, as before.
- Change a signal, a superseding check, and a lost runner to record every running stage, not only one.
- Add tools-test cases for two free stages overlapping, test-run starting only after test-build passed, a failing stage failing the check with its own log, every stage line recorded, `CHECK_JOBS=1` running stages one at a time, and a killed check recording each running stage.
- Document the parallel check in the README, the codebase map, the Makefile `stages` comment, and the checker agent.
- Add the change's line to Sprint 13 of the backlog queue as the sprint's user-approved exception, the planner's queue, and the metrics history row of sprint-security.
- Record the review findings left for later in the change's findings file.

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding: high 0, medium 1 at confidence 6 and low 1, both recorded as findings.
- Run the checker's fast stages through one real parallel `sh tools/run_state.sh check` with `CHECK_JOBS=3`, every stage passes (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates) in 368 s of wall time against the 630 s sequential figure.
- Run the quality review, pass with no blocking finding and 7 advisories.
- Run the benchmark review, pass with no allocation or round regression.
- Run `make spec-validate` after the archive, 53 passed and 0 failed.
- Run `make gates` and `make docs-lint` before the push, both pass.

---

## Notes

- The shared compile cache build/spinel-cache is safe under concurrent writers since Spinel stores each object by writing a file named with its process id and renaming it over the entry; every other build path is the stage's own.
- `make check`, `make check-stage S=NAME`, and CI are unchanged.
- Follow-ups recorded in the findings file: the job files beside the check clone let branch code forge a stage's pass record (security Medium, confidence 6, not blocking since the toolchain symlink already reaches the run state), the failing log excerpt is printed without stripping control characters (security Low), a compile stage passed while the check stops is not recorded as compiled, and a lost runner's stage jobs keep running.
- Of the quality advisories, the design drift on the poll sleep is fixed in the archived design; the dead loop in stages_start, the repeated `CHECK_JOBS` refusal, the duplicated stop word and seconds, and the extra blank line are style advisories left as they are.
