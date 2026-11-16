fix(pipeline): plan only when needed and count only real sprint merges

## Summary

Skips the planner whenever plan-needed finds no decision to make, keeps never-merged runs out of the metrics history, and leaves changes marked beyond the sprint out of the sprint's count of five. A brief fixing the order still started a full planner (#136 spent 41,075 of 242,766 tokens and 20 calls on it), history appended a row for a run whose merge commit main never held, and review-due counted a user-approved extra change, closing the sprint one change early.

---

## Changes

- Change the deliver workflow's Plan phase to run only when plan-needed prints needed, through a pure planSkipped helper, so a brief for the queue's head no longer starts the planner while it still reaches the scouts and the contributor.
- Change pending_list in tools/run_state.sh to list a merged run only when git knows its merged commit on HEAD or on origin/main, so history, bench, plan-needed, and review-due never take a never-merged run, and history names each run it leaves out.
- Change review-due and groom's sprint row to leave out of the count a change whose queue item carries beyond the sprint in its parenthesis, while the due line still lists it so the sprint review covers its diff; the user-approved exception, which lifts only the one-pipeline limit, still counts.
- Add tools_test cases that fail before and pass after each fix: a fixed-order brief skips the planner, a never-merged run gets no row, a marked change does not count, and a change marked only for the pipeline limit still counts.
- Document the planner trigger and the sprint count in the README pipeline section and the new helpers in the codebase map's tools/run_state.sh entry.
- Archive the sprint-tidy OpenSpec change with skip_specs, record the planner's queue and the metrics history row, and append the review's non-blocking findings to the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding and none blocking; its one Low at confidence 3 is appended to the backlog.
- Run the quality review, pass with no blocking finding after one fix round; its advisories are appended to the backlog.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the benchmark comparison against main's recorded figures, pass.
- Run make spec-validate after the archive, 51 passed and 0 failed.

---

## Notes

The planner did not split the item, so there is no part b. The marker beyond the sprint is not yet named in the planner's instructions, so only an edit of docs/queue.md marks an item for now; that follow-up and the run_state.sh duplications the quality review found are in the backlog. Existing rows of docs/metrics.tsv stay as they are, since history only appends.
