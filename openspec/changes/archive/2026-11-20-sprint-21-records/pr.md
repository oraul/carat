chore(sprint-21): record the sprint and apply the next queue

## Summary

Applies the sprint-21 records: the metrics history, the backlog grooming, the two lane queues of sprint 22, and the sprint row. It is needed so the queues, the backlog, and the sprints file match the changes merged in sprint 21, with the planner's plan applied once.

---

## Changes

- Fold the findings files of the sprint's deliveries into the backlog, remove them, and remove the groomed headings
- Replace the feature and backlog lane queues with the sprint-22 revision, the backlog queue trimmed to the shared byte budget
- Append the sprint-21 row to the sprints file and the pending history rows to the feature and backlog metrics files
- Replace a backticked path to a removed findings file in the backlog with plain words
- Archive the records change as an OpenSpec change that alters no behavior and record the non-blocking advisories in its findings file

---

## Testing

- Run the security review at 528d21f2c165, no High, Medium, or Low finding, nothing blocking
- Run the check stages at 528d21f2c165, all pass
- Run the benchmark at 528d21f2c165, nothing blocking
- Run the quality review at 934b93604302, nothing blocking, advisories recorded in the findings file
- Run spec-validate, 54 passed, 0 failed

---

## Notes

The last fix round changed only records, so the check, the security review, and the benchmark were not rerun after 528d21f2c165. Two backlog advisories about the folded entries are recorded in the findings file for a later grooming.
