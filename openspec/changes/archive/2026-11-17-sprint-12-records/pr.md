docs: apply the sprint-12 plan to the backlog and queues

## Summary

Applies the sprint-12 plan: the metrics history rows of both lanes, the backlog grooming with the seven findings files folded in, the two lane queues of sprint 13, and the sprint-12 row of the sprints file. The plan is applied once by its records change, so the queues, the backlog, and the history match the merged work before sprint 13 starts.

---

## Changes

- Fold the seven findings files of sprint 12 into docs/backlog.md and remove them, and drop the 13 headings the merged items listed
- Copy the sprint plan's two lane queues over docs/queue-feature.md and docs/queue-backlog.md for sprint 13
- Append the history rows of lsp-container and planner-split-rule to their lane's metrics file
- Append the sprint-12 row to docs/sprints.tsv
- Record the three non-blocking quality findings of this change in docs/findings/sprint-12-records.md
- Add the archived OpenSpec change sprint-12-records with skip_specs, since no behavior changes

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and three advisories recorded as findings
- Run the checker's fast stages, all pass
- Run make spec-validate, all 53 items pass
- Run make gates and make docs-lint, both pass

---

## Notes

The backlog changes are what groom wrote, apart from one backticked path of a removed findings file that make docs-lint refused, now named in prose. The duplicate headings from the markdown-reading-c double append and the missing blank lines before some folded headings are left for the next grooming, as recorded in the findings file.
