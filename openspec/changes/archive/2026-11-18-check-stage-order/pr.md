fix(run-state): start the gates stage only after test-build

## Summary

Makes `sh tools/run_state.sh check` start the gates stage only after test-build has finished compiling the test runner. Without that order a change that edits a test failed gates within a second because its snapshots gate found build/test/run_all missing, and the still running test-build and diagnose stages were killed with it.

---

## Changes

- Fix the stage order by adding the `gates:test-build` pair to `STAGE_AFTER` in `tools/run_state.sh`, so gates waits for test-build even when it is queued first
- Document in the `STAGE_AFTER` comment why gates needs the runner and why diagnose, which reads only the runner's source, stays free
- Add two `tools/tools_test.sh` cases: a parallel check with gates queued before test-build passes, and gates starts only after test-build ended
- Archive the OpenSpec change `check-stage-order` with its proposal, design, and tasks, no spec changing
- Record the backlog lane's plan in `docs/queue-backlog.md` and the review-lite metrics row in `docs/metrics-backlog.tsv`

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding; its one advisory on the proposal's assumption was fixed in place
- Run the checker's stages at ec71a7b36c15 (diagnose, docs-lint, dev-build, test-build, bench-budget, tools-test, test-run, gates, metrics), all pass, gates included on a branch that edits a test file
- Run `make tools-test` with the two new stage order cases, 1754 of 1754 pass
- Run `make spec-validate` after the archive, 54 of 54 pass
- Run the benchmark review against main's figures, pass with no allocation or round change

---

## Notes

This fixes the defect the gutter-signcolumn delivery recorded in its findings: gates failed after 1 s at 118500e1d053 before test-build had compiled build/test/run_all, killing test-build and diagnose after 28 s, so that entry can be removed once it is folded in. The change edits `tools/run_state.sh` only, not `tools/rules.sh`. Gates can now start up to test-build's remaining time later than before, since the fast free stages ahead of it end early.
