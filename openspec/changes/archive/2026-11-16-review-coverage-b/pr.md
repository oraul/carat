fix(pipeline): clear a failing security review only by a later plan

## Summary

Makes the delivery pipeline run the planner while a periodic security review holds a blocking finding that no delivery planned after it has merged past and no later periodic security review has superseded, and caps the changes a sprint may leave out of its count so the sprint-end review always fires and reads every merged diff. Sprint 8's review found that a delivery of the queue head skipped the security-first stop because plan-needed never read the review run states, and the quality review of pull request 149 then found that clearing the review on any later merge let a delivery planned before the review clear it although no planner had read it.

---

## Changes

- Change plan-needed to print needed when a review or sprint run state records a failing periodic security review, naming the review run so the planner reads it and applies its security-first step
- Fix merged_since so a merge clears a failing periodic security review only when the merged change's phase.plan strictly descends from the reviewed commit and its planner was not skipped, reading every history row merged after the reviewed commit so a cleared review stays cleared past later skipped planners
- Add passed_since so a passing periodic security review at a later commit supersedes a failing one, while a pass of the same commit leaves it standing
- Add a planner prompt line in the delivery workflow that names the failing review run plan-needed found, and point the planner agent at that run's show
- Change review-due, groom, and the sprint row to leave at most one change marked beyond the sprint out of a sprint's count, and end the sprint row at the fifth counted change so a later exception falls into the next sprint's combined diff
- Refactor the review-run and plan-record reads in run_state.sh to avoid a subprocess per file
- Add tools-test cases for a merge planned before the review, a merge with a skipped planner, a merge planned after it, that merge followed by two skipped planners, a same-commit pass, a later superseding pass, the exception cap, and the corrected sprint row
- Document the planned-after rule, the superseding pass, and the capped sprint exception in the README pipeline section, the run_state.sh header, the planReview comment, and the code map
- Archive the review-coverage and review-coverage-b OpenSpec changes, apply the planner's queue, and append the review findings left for later to the backlog

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding; one Medium (confidence 6) and one Low (confidence 4) finding on passed_since and merged_since are appended to the backlog
- Run the quality review, pass with no blocking finding after one round fixing a blocking finding on skipped-planner merges; its advisories are appended to the backlog
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass, tools-test 1313 of 1313 cases in 107 s
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after the archive, 53 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

This pull request supersedes pull request 149, which carries the review-coverage commits included here unchanged and could take no further push after its quality review blocked; the user closes 149 after this one merges. A plan recorded at the reviewed commit itself does not clear the review, since its time against the review's cannot be told from the commit, so the rule fails closed and the next planned delivery clears it. The change alters only the delivery pipeline, which no spec describes, so both OpenSpec changes are archived without spec deltas. Tools-test time was measured only in the checker's stage on this branch, not side by side with main.
