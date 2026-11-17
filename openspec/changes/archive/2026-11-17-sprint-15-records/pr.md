docs: apply the sprint-15 plan and records

## Summary

Applies the sprint-15 records: the next sprint's feature and backlog queues, the lanes' metrics history rows, the sprint's row in docs/sprints.tsv, and the findings files folded into docs/backlog.md. Sprint planning closed sprint 15 after its fifth merge, and its records change is the one place those records land, alone and once.

---

## Changes

- Fold the pending findings files of ci-trust-gaps, motions-search-tidy, record-squash-commit, ruby-structure-remove, sprint-14-records, tab-close-c, and vim-folds-a into docs/backlog.md and remove the folded files
- Change docs/queue-feature.md and docs/queue-backlog.md to the sprint-16 queues the planner groomed
- Add the sprint-15 row to docs/sprints.tsv and the pending lane rows to docs/metrics-feature.tsv and docs/metrics-backlog.tsv
- Add the archived OpenSpec change 2026-11-17-sprint-15-records, with no delta specs
- Add docs/findings/sprint-15-records.md with the two non-blocking findings of this change's quality review

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and two advisories recorded in docs/findings/sprint-15-records.md
- Run the checker's fast stages, all pass, the build, test, diagnose, bench, metrics, and tools stages scoped out as the diff touches no code
- Run make spec-validate, 54 items pass
- Run make gates and make docs-lint, both pass

---

## Notes

The change holds records only, no code. The two advisories, a findings file's title folded as a second level-one heading and seven folded headings with no blank line before them, both groom defects in folded_backlog of tools/run_state.sh, are left to a backlog change so this change applies groom's output unchanged.
