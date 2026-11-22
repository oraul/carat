chore(docs): record sprint-27 and queue the next sprint

## Summary

Applies the sprint-27 plan: files the sprint's findings into the backlog, records the sprint's metrics history, and queues the next sprint's two lanes. Sprint-27 closed with six merged changes and these records keep the queues and the sprint table current for the next one.

---

## Changes

- Append the sprint-27 row to docs/sprints.tsv
- Copy the feature and backlog lane queues of the next sprint into docs/queue-feature.md and docs/queue-backlog.md
- File each findings entry under the backlog file of its first named path in docs/backlog/ and drop the findings files it consumed
- Append the pending metrics history rows for the sprint's changes
- Add the word estimated before the size of each Pool item of docs/queue-feature.md so the queue lint passes
- Archive the sprint-27-records OpenSpec change with no spec delta

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the benchmark review, pass with no blocking findings
- Run make spec-validate, all 56 items pass
- Run the check stages at the head, all pass
- Run make gates and make docs-lint at the head, both pass

---

## Notes

None
