chore(records): apply the sprint-24 plan and history rows

## Summary

Applies the sprint-24 plan: appends the sprint's history rows, folds the findings files into the backlog, copies the two lane queues, and records the sprint's row. This keeps the planning records current so sprint 25 starts from the groomed backlog and the new queues.

---

## Changes

- Fold the findings files into docs/backlog.md with the groom pass and drop the folded findings files
- Replace docs/queue-feature.md and docs/queue-backlog.md with the sprint's two lane queues
- Append the pending lane rows to docs/metrics-feature.tsv and docs/metrics-backlog.tsv
- Append the sprint-24 row to docs/sprints.tsv
- Add the archived OpenSpec change for the records, with skip_specs set because no behavior changes
- Record the review advisories in docs/findings/sprint-24-records.md for the next grooming

---

## Testing

- Run make spec-validate, 55 passed, 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass
- The check, the security review, and the benchmark last ran at 40159f805806, which holds the applied records; the later commits changed only records and the archive

---

## Notes

No code changes. Advisories about repeated headings, stale queue references, and the missing ci key of the review-trust-lows-b metrics row are recorded in the findings file for the next grooming and a pipeline change.
