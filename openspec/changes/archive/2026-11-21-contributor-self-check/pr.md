chore(workflow): let the contributor check itself before returning

## Summary

Lets the contributor run the delivery check itself at its head before returning implement or fix, and lets the checker skip the stages that check already passed at that head while still confirming the run. Most failed checks were stages the implement session could have run, and each failure cost a fresh contributor start, because the guard refused the contributor the check and the checker reran every stage anyway.

---

## Changes

- Change tools/agent_guard.sh so the contributor may run `run_state.sh check CHANGE` with no commit argument, while a COMMIT, metric, settled, and moved stay refused.
- Change `run_state.sh check CHANGE COMMIT` to count stage records only when the COMMIT is the recorded phase.check or HEAD; any other COMMIT backs nothing and every stage runs, and the header and comments say the workflow trusts a pass only from the runner's own stage records, whoever started the check.
- Add a machinery line to tools/lane_facts.sh that says whether the diff from the merge base touches tools/, the Makefile, or test/runner/.
- Change the delivery workflow so a contributor's verdict that every stage passed at its returned head, on a lane whose machinery line is no, makes the checker's check back that head; any other claim leaves the backed commit at phase.check, so a false claim costs only a stage run and no new contributor start.
- Add the check and check_runs fields to the contributor's result and a self_fix metric that counts each start's check reruns after its first.
- Change CALL_CAPS for implement from 90 to 110 and for fix from 40 to 60, and the contributor's maxTurns from 140 to 170 to match the caps formula.
- Change the contributor's card rule 2 and its copy in the workflow to require a passing check at HEAD, and add a Checking section to docs/contributor-notes.md with the steps, the three-run limit, and how to read a failure.
- Change the openspec/config.yaml apply guidance to order the session as tasks, quality fixes, commit, docs-lint and gates, merge-main if behind, then the check and its fixes.
- Document the new phases in CLAUDE.md, README.md, the checker's agent file, docs/goals.md, and the code map.
- Add tools-test cases for the guard, the backed head and its machinery fallback, a false claimed pass, a COMMIT other than phase.check, and the self_fix metric, and record the plan, the metrics history row, the Sprint 25 exception line, and the findings.

---

## Testing

- Run the security review of the committed diff at 4b3908da87aa: pass, high 0, medium 0, low 1, blocking 0; the Low is recorded in the findings file.
- Run the checker's stages at 4b3908da87aa (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics): all pass.
- Run the benchmark review at 4b3908da87aa: pass, blocking 0.
- Run the quality review of the diff: 6 findings, 4 fixed and 2 recorded in the findings file.
- Run make spec-validate after the archive: 55 passed, 0 failed.
- Run make gates and make docs-lint at the packaged head: all pass.

---

## Notes

The guard is read from main, so this delivery itself ran the old path; its tools-test cases prove the new one. tools/rules.sh is untouched. The Low security finding, that a backed head trusts stage records the contributor's session could write through an uncommitted edit of the runner, is recorded in docs/findings/contributor-self-check.md with a fix outline; CI and main's merge gates still rerun every stage except diagnose. self_fix stays a run-state metric with no history column, since the feature lane's metrics file is out of scope.
