chore(sprint-20): record the sprint and apply the next queue

## Summary

Applies the sprint-20 records: the metrics history, the backlog grooming, the two lane queues of sprint 21, and the sprint row. It is needed so the queues, the backlog, and the sprints file match the six merged changes of sprint 20, with the planner's plan applied once.

---

## Changes

- Fold the findings files of the sprint's deliveries into the backlog, remove them, and remove the groomed headings
- Replace the feature and backlog lane queues with the sprint-21 revision
- Append the sprint-20 row to the sprints file and the pending history rows to the feature and backlog metrics files
- Correct the calibration decision in the backlog queue to say quality first pass 1 of 7 in sprint-20, 1 of 8 with finder-grep
- Archive the records change as an OpenSpec change that alters no behavior and record three non-blocking advisories in its findings file

---

## Testing

- Run the security review at 437dd548526c, no High, Medium, or Low finding, nothing blocking
- Run the check stages at 437dd548526c, all pass
- Run the benchmark at 437dd548526c, nothing blocking
- Run the quality review at 8f8f514ffa5e, nothing blocking, three advisories recorded in the findings file
- Run spec-validate, 54 passed, 0 failed

---

## Notes

None
