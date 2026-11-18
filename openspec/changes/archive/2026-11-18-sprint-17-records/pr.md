chore: apply the sprint-17 records

## Summary

Applies the sprint-17 plan: the metrics history rows of the sprint's last deliveries, the backlog grooming with the folded findings files, the two lane queues of sprint 18, and the sprint-17 row of the sprints file. Sprint 17 closed with its six changes merged, and its records are applied once, by this records change, so the queues, the backlog, and the history match the merged work before sprint 18 starts.

---

## Changes

- Fold the seven findings files of sprint 17 into the backlog and remove them, dropping the 14 headings the grooming listed as fixed, listed by a merged item, or duplicate
- Change the feature and backlog queues to the sprint 18 choice: features guide-colors, facet-palette, and background-default; backlog groom-proof, sign-colors, and lsp-tidy
- Add the pending history rows of squash-body-full and vim-line-commands-c to the metrics history files
- Add the sprint-17 row to docs/sprints.tsv
- Fix the review advisories in the queues and put three paths to removed findings files in prose
- Add docs/findings/sprint-17-records.md with the two backlog duplications the review found, left for the next grooming
- Add the archived OpenSpec change sprint-17-records, with no spec change

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding and nothing blocking
- Run the quality review, pass with nothing blocking, its advisories fixed in place or recorded in the change's findings file
- Run the checker's stages with make check, every stage passes
- Run make spec-validate, all 54 items pass
- Run make gates and make docs-lint, both pass

---

## Notes

This records change carries no code, test, tool, or spec change. Both copies of the duplicate finding about a records change resuming into the planner stay in the backlog until groom-proof narrows the groom guard, by the main session's decision; no finding is reworded.
