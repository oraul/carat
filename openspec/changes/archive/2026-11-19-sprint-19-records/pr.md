chore(sprint-19): record the sprint and apply the next queue

## Summary

Records sprint 19: appends the metrics history rows, folds the sprint's findings into the backlog, and installs the next sprint's two lane queues. This keeps the planning records current so the next sprint starts from the groomed queue.

---

## Changes

- Append every lane's pending metrics history rows
- Fold the findings files of the sprint into the backlog with groom
- Copy the sprint's feature and backlog lane queues and append the sprint 19 row to docs/sprints.tsv
- Archive the sprint-19-records OpenSpec change with skip_specs, no code touched
- Record three non-blocking quality findings in docs/findings/sprint-19-records.md

---

## Testing

- Run make spec-validate, all 54 items pass
- Security review of the committed diff, no findings: the change touches only planning records and docs

---

## Notes

None
