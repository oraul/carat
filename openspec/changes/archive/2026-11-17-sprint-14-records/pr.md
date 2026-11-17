docs: apply the sprint-14 plan and records

## Summary

Applies the sprint-14 records: the next sprint's feature and backlog queues, the lanes' metrics history rows, the sprint's row in docs/sprints.tsv, and the findings files folded into docs/backlog.md. Sprint planning closed sprint 14 after its fifth merge, and its records change is the one place those records land, alone and once.

---

## Changes

- Fold the pending findings files of sprint 13 records, markdown-reading-d, merge-record-check, tab-close-b, and vim-line-commands-a into docs/backlog.md and remove the folded files
- Change docs/queue-feature.md and docs/queue-backlog.md to the sprint-15 queues the planner groomed
- Add the sprint-14 row to docs/sprints.tsv and the pending lane rows to docs/metrics-feature.tsv and docs/metrics-backlog.tsv
- Add the archived OpenSpec change 2026-11-17-sprint-14-records, with no delta specs
- Add docs/findings/sprint-14-records.md with the two non-blocking findings of this change's quality review

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and two advisories recorded in docs/findings/sprint-14-records.md
- Run the checker's fast stages, all pass, the build, test, diagnose, bench, metrics, and tools stages scoped out as the diff touches no code
- Run make spec-validate, 53 items pass
- Run make gates and make docs-lint, both pass

---

## Notes

The change holds records only, no code. The two advisories, a missing blank line before one folded backlog heading and two defects recorded twice, are left to the next grooming so this change applies groom's output unchanged.
