fix(pipeline): keep periodic security reviews and sprint counts in check

## Summary

Makes the delivery pipeline run the planner when a periodic security review recorded a blocking finding that no later merge has passed, and caps the changes a sprint may leave out of its count so the sprint-end review always fires and reads every merged diff. Sprint 8's review found that a delivery of the queue head skipped the security-first stop because plan-needed never read the review run states, that changes marked beyond the sprint could keep review-due from ever reaching five, and that an exception's row after the fifth counted change fell outside every sprint's combined diff.

---

## Changes

- Change plan-needed to print needed when a review or sprint run state records a failing periodic security review and no change merged after the reviewed commit, naming the review run so the planner reads it and applies its security-first step
- Add a planner prompt line in the delivery workflow that names the failing review run plan-needed found, and point the planner agent at that run's show
- Change review-due, groom, and the sprint row to leave at most one change marked beyond the sprint out of a sprint's count, so a sprint closes after at most six merges whatever the markers say
- Fix the sprint row to end at the fifth counted change, so an exception merged after it falls into the next sprint's combined diff
- Refactor the sprint exception loop into a plain condition that stops reading queues once the cap is reached, and read the review run states without a subprocess per file
- Add tools-test cases for the failing review trigger, its clearing by a later merge, the exception cap, and the corrected sprint row
- Document the capped sprint exception and the planner trigger in the README pipeline section and the run_state.sh entry of the code map
- Archive the review-coverage OpenSpec change, apply the planner's queue, append the merged runs' metrics row, and append the review findings left for later to the backlog

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding; one Low finding about merged_since clearing a review on an earlier-planned merge is appended to the backlog
- Run the quality review, pass with no blocking finding; its advisories are appended to the backlog
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after the archive, 53 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The change alters only the delivery pipeline, which no spec describes, so the OpenSpec change is archived without spec deltas. The cap is one exception per sprint, taken by the first marked change in merge-row order; sprint 9 holds one, spinel-notice. A failing periodic security review is cleared by any merge after the reviewed commit, on the premise that the merging delivery's planner saw it; the backlog entries added here record where that premise can fail and how to tighten it. Tools-test time held: three runs measured 99.9 s on the branch against 100.7 s on main.
