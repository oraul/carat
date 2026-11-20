chore(sprint-22): record the sprint and apply the next queue

## Summary

Applies the sprint-22 records: the metrics history, the backlog grooming, the two lane queues of sprint 23, and the sprint row. It is needed so the queues, the backlog, and the sprints file match the changes merged in sprint 22, with the planner's plan applied once.

---

## Changes

- Fold the findings files of the sprint's deliveries into the backlog, remove them, and remove the groomed headings
- Replace the feature and backlog lane queues with the sprint-23 revision
- Append the sprint-22 row to the sprints file and the pending history rows to the feature and backlog metrics files
- Reword three folded backlog entries that named a removed findings file as a location, in plain words
- Archive the records change as an OpenSpec change that alters no behavior

---

## Testing

- Run the security review at c1fd106cfc1a, no High, Medium, or Low finding, nothing blocking
- Run the check stages at c1fd106cfc1a, all pass
- Run the benchmark at c1fd106cfc1a, nothing blocking
- Run the quality review at 4ad4319c3d38, nothing blocking, no advisories
- Run spec-validate, 54 passed, 0 failed

---

## Notes

The last fix round changed only records, so the check, the security review, and the benchmark were not rerun after c1fd106cfc1a.
