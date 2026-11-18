chore(pipeline): fix review findings in place and slim the check

## Summary

Makes the delivery workflow run the check itself, ask the first quality pass for every blocking finding, fix security findings and quality advisories in the change's own files in place in the same pull request with the check and both reviews run again at the new head, and set sprint-planning's own starts apart from the records change's budget. Over the last 24 deliveries a change averaged 1,091,490 total and 183,053 output tokens, blocking findings surfaced one round at a time, Lows left in a change's own files came back as a sprint Medium, and every records row stood over 500,000 tokens because the sprint review was counted in it.

---

## Changes

- Change the check phase so the workflow builds the check's command lines and a cheap start runs only those, the checker's reading start running only on a failed stage, never on a pass.
- Change the quality first pass to report every blocking finding it can find in the whole diff, a re-review checking the fix and the findings left.
- Add the fix-in-place round: security findings of any severity in code the change touches and quality advisories go to the contributor once, are fixed when the fix stays in the change's files and adds no behavior, each a task of its tasks.md, then the check, the security review, and the quality review run again at the new head within the three rounds, and only findings the reviewers confirm fixed leave the findings file.
- Change the token accounting so sprint-planning's own starts are keyed as sprint and the budget of a sprint-N-records change subtracts them, naming them set apart.
- Document the new process in docs/goals.md, the CLAUDE.md Agents section and findings convention, the README pipeline steps, and the checker and quality reviewer files.
- Add tools-test cases for the checker relay skipped on a pass and started on a failure, the quality first pass asked for every blocking finding, the fix-in-place round re-running check, security, and quality, and a records budget without sprint-planning's starts.
- Record the nine quality advisories left unfixed in docs/findings/pipeline-diet-b.md, duplicates merged, and apply this lane's queue plan and metrics row.

---

## Testing

- Run the security review on the committed diff at fd7463aa8c94, pass with 0 High, 0 Medium, 0 Low, 0 blocking.
- Run the checker's fast stages at fd7463aa8c94 (docs-lint, dev-build, test-build, diagnose, test-run, gates, bench-budget, metrics), all pass.
- Run make tools-test at fd7463aa8c94, all pass.
- Run the quality review at fd7463aa8c94, pass with 0 blocking findings and 9 advisories, recorded in the findings file.
- Run the benchmark review at fd7463aa8c94, pass with 0 blocking findings.
- Run make spec-validate after the archive, 54 passed and 0 failed.

---

## Notes

The change alters no specified behavior, so it is archived with skip_specs. It leaves tools/rules.sh and .claude/agents/contributor.md untouched, the fix-in-place instruction riding in the workflow's fix prompt, and touches no file of the feature lane. At the package step the run state records 366,680 total tokens (package, CI, and merge not yet counted) against the 1,091,490 average and 350,870 output tokens against the 183,053 average, an output overrun noted for the planner. It removes the pool item records-budget-scope, which this change delivers.
