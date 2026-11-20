chore(records): apply the sprint-23 plan

## Summary

Records sprint 23: folds the sprint's findings into the backlog, installs the next feature and backlog queues, and appends the sprint row and the lane metrics history rows. The sprint's records change is the one place that applies the planner's output, so the next sprint starts from current queues.

---

## Changes

- Fold the findings files of the sprint into the backlog and delete the folded files.
- Replace the feature queue and the backlog queue with the sprint-23 plan's.
- Append the sprint-23 row to the sprints table.
- Append the pending metrics history rows of the feature and backlog lanes.
- Record the quality advisories of this change in its findings file.
- Archive the change with its proposal, design, and tasks, no delta spec.

---

## Testing

- Run the check stages at 5835ea2e7f71, all pass.
- Run the security review of the committed diff at 5835ea2e7f71, pass with no blocking finding.
- Run the benchmark at 5835ea2e7f71, skipped as scoped for a records-only change.
- Run make spec-validate after archiving, all 54 items pass.
- Run make gates and make docs-lint at the head, pass.

---

## Notes

The last fix round changed only records, so the check, the security review, and the benchmark are named at 5835ea2e7f71. Seven quality advisories are recorded in the change's findings file for the next records change.
