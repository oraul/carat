docs: apply the sprint-13 plan and records

## Summary

Applies the sprint-13 plan: the backlog grooming, the sprint-14 lane queues, the pending metrics history rows, and the sprint-13 row of the sprints file. The plan waited in the build directory after sprint 13 closed, and the queues, backlog, and records must match the merged work before sprint 14 starts.

---

## Changes

- Change docs/backlog.md by removing the 14 groomed headings (10 listed by merged items, 1 fixed by a merged commit, 3 duplicates), folding in the seven findings files of the sprint, and appending the grooming entries
- Remove the folded findings files under docs/findings
- Change docs/queue-feature.md and docs/queue-backlog.md to the sprint-14 lane queues of the plan
- Add the history rows of bar-colors and tab-close to docs/metrics-feature.tsv and docs/metrics-backlog.tsv
- Add the sprint-13 row to docs/sprints.tsv
- Add docs/findings/sprint-13-records.md with the five quality advisories on the groomed backlog, for the next grooming
- Add the archived OpenSpec change sprint-13-records, with skip_specs set since no behavior changes

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding and nothing blocking
- Run the quality review, pass with nothing blocking and five advisories recorded in docs/findings/sprint-13-records.md
- Run the checker's fast stages, all pass, the build, test, diagnose, bench, metrics, and tools stages scoped out as the diff touches no code
- Run make spec-validate, all 53 items pass
- Run make gates and make docs-lint, both pass

---

## Notes

This is the sprint's records change, outside the sprint count; it carries no code, test, tool, or spec change. The groomed backlog still holds duplicated and misformatted folded entries from the groom itself, recorded as advisories for the next grooming rather than hand-edited here.
