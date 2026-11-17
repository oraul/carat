chore(pipeline): make a sprint six changes, three and three, from sprint-17

## Summary

Makes a sprint six counted changes from sprint-17 on, three features and three backlog changes, while sprint-16 and earlier still close at their fifth counted merge. The user asked to calibrate the sprint with one more backlog item for now, keeping the three features, starting with Sprint 17 so Sprint 16 finishes as planned.

---

## Changes

- Change `tools/run_state.sh` so review-due, the sprint row, and groom count six rows from sprint-17 and five before it, through SPRINT_SIZE and SPRINT_SIZE_FROM
- Change the backlog pick to draw three backlog batches for a sprint, and the docs-lint queue check to accept three backlog items in a sprint
- Add tools-test cases for review-due not due at sprint-17's fifth counted merge and due at its sixth, sprint-16 still due at its fifth, the sprint row and groom taking six rows from sprint-17, and the pick drawing three batches
- Change the planner, retrospective, /sprint, sprint-planning, and deliver-change texts to a sprint of six, three and three, five before sprint-17
- Document the rule in CLAUDE.md, the README's pipeline description, and the codebase map
- Document the user's decision of 2026-11-17, for now, in docs/goals.md, stating the current sprint rule first and keeping the earlier dated decisions as history
- Add the user-approved exception line for this change under Sprint 16 in docs/queue-backlog.md, apply this lane's plan, and append the lane's metrics history row

---

## Testing

- Run the security review of the committed diff, pass with 0 high, 0 medium, 0 low findings
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, test-run, gates, bench-budget, tools-test, and metrics, all pass
- Run the quality review, pass with 0 blocking and 2 advisories
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make docs-lint after the package edits, all checks pass

---

## Notes

The one-pipeline-change rule and the exception rules are unchanged; T0 items stay outside the sprint and go first. Of the two quality advisories, the docs/goals.md wording one is fixed in this change; the other is dropped from the findings file as a later cleanup, not a defect: once sprint-16-records merges, SPRINT_SIZE_FROM, SPRINT_SIZE_BEFORE, and the sprint-16 branch in `tools/run_state.sh` and the five-before-sprint-17 parentheticals in the docs can be removed, keeping the dated decision only in docs/goals.md.
