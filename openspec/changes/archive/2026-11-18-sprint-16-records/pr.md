docs: apply the sprint-16 plan and records

## Summary

Applies the sprint-16 plan: the sprint's findings files are folded into the backlog, the two lane queues for the next sprint are copied in, the pending metrics history row is appended, and the sprint-16 row is added to the sprint records. The sprint-planning workflow closes each sprint through exactly one records change so the backlog, queues, and sprint figures move together on main.

---

## Changes

- Fold the eight findings files of the sprint into docs/backlog.md and remove them from docs/findings
- Replace docs/queue-feature.md and docs/queue-backlog.md with the next sprint's lane queues from the plan, the security-first item moved-review-carry already merged as 199
- Append the sprint-16 row to docs/sprints.tsv and the pending moved-review-carry row to docs/metrics-backlog.tsv
- Record this change's six non-blocking review findings in docs/findings/sprint-16-records.md for the next grooming
- Add the archived OpenSpec change sprint-16-records with skip_specs set, since no behavior changes

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding and nothing blocking
- Run the quality review, pass with nothing blocking and six advisories recorded in the findings file
- Run the checker's fast stages (dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, docs-lint, gates), all pass
- Run the benchmark review, pass with nothing blocking
- Run make spec-validate after archiving, 54 passed and 0 failed

---

## Notes

The sprint-16 row names moved-review-carry in place of plugin-lazy-activate, whose history row is still only on its own branch, so the row's figures describe a slightly different set of six changes; the findings file records the fix to sprint_row and a later records change to rewrite the row. The new backlog Pool drops several items without a Decisions line; the next planner run is to state each drop or restore them.
