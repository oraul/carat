chore(records): apply the sprint-25 plan

## Summary

Records the sprint-25 plan: the pending metrics rows, the findings filed into the backlog, the two next lane queues, and the sprint's row. This keeps the planning data in the repository so the next sprint starts from it.

---

## Changes

- Append the pending lane rows to docs/metrics-feature.tsv and docs/metrics-backlog.tsv
- File each findings entry into the backlog file of its first named path under docs/backlog and remove the filed findings files
- Copy the sprint's two lane queues to docs/queue-feature.md and docs/queue-backlog.md
- Append the sprint-25 row to docs/sprints.tsv
- Add the archived sprint-25-records OpenSpec change, with no delta spec and skip_specs set

---

## Testing

- Run make spec-validate, all 55 items pass
- Run the stages of the checker at the implement head, docs-lint and gates pass and the code stages are scoped out as the diff holds no code
- Security review of the committed diff is run by the workflow before the merge and reported there

---

## Notes

None
