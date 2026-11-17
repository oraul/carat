docs: apply the sprint-11 plan and its records

## Summary

Applies the sprint-11 plan once: the backlog grooming, the sprint-12 lane queues, the pending metrics history rows, and the sprint-11 row of the sprints file. The plan waits in the build directory until its records change commits it, so the queues, the backlog, and the history must match the merged work before sprint 12 starts.

---

## Changes

- Add the pending history rows of both lanes, ux-fixes-a to the feature metrics and windows-tabs-tidy to the backlog metrics
- Change the backlog by removing the entries the sprint plan listed as merged or duplicate, folding in the four delivery findings files, and appending the groomed entries
- Change both lane queues to the sprint-12 order the sprint plan wrote
- Add the sprint-11 row to the sprints file
- Add the archived OpenSpec change with skip_specs set, and record the seven advisory review findings for the next grooming

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings and seven advisories recorded as findings
- Run the checker's fast stages, all pass, docs-lint and gates in full and the build, test, diagnose, bench, metrics, and tools stages scoped out as no code changed
- Run make spec-validate after the archive, 53 of 53 pass
- Run make gates and make docs-lint before the push, all pass

---

## Notes

The change alters no code, test, or tool; it is a T0 delivery record outside the sprint count. The archived proposal says groom removes 22 headings from the backlog, while 20 were removed there and 2 were duplicate copies inside the ux-fixes-a findings file; this is recorded as a finding rather than edited after the review.
