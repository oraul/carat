docs: apply the sprint-18 plan and records

## Summary

Applies the sprint-18 plan: the findings files are folded into the backlog, the two lane queues for sprint 19 are in place, and the sprint's row and the pending metrics rows are recorded. Sprint 18 has closed, and the next deliveries read their order from these records, so main needs them before sprint 19 starts.

---

## Changes

- Fold the sprint's findings files into docs/backlog.md through groom, removing the folded files under docs/findings
- Replace docs/queue-feature.md and docs/queue-backlog.md with the planner's sprint-19 queues, as the planner revised them at the user's request, with the sprint-19 features gutter-signcolumn, match-paren, and cursor-and-messages, and the backlog items review-lite, quality-first-pass, and contributor-checklist under the user-approved exception
- Drop the queue section and Decisions bullets that still named the merged groom-security-mark, and cite only the user's request in the feature queue's first decision
- Append the sprint-18 row to docs/sprints.tsv and the history rows of background-default and groom-security-mark to the lane metrics files
- Unquote the removed findings directory in one backlog line so docs-lint passes, recorded in the change's design
- Record this change's non-blocking review findings in docs/findings/sprint-18-records.md for the next grooming
- Add the archived OpenSpec change sprint-18-records, with no spec changes

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking findings and four advisories, recorded in the findings file
- Run the checker's fast stages, all pass, with build, test, diagnose, metrics, and tools-test scoped or carried since the diff touches only records and docs
- Run the benchmark review, pass with no blocking findings
- Run make spec-validate, make gates, and make docs-lint, all pass

---

## Notes

This change holds records only and no code. The first start stopped at the plan for a periodic security finding in tools/run_state.sh, fixed by groom-security-mark as #214 before this run resumed. The backlog advisories it raises, such as duplicate folded entries, stale security entries now fixed by #214, and missing blank lines around folded headings, are left for the next grooming by design, since a delivery does not edit the backlog by hand.
