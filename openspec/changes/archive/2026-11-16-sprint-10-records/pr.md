docs: apply the sprint-10 plan and its records

## Summary

Applies the sprint-10 plan once: the backlog grooming, the sprint-11 lane queues, the pending metrics history rows, and the sprint-10 row of the sprints file. The plan waits in the build directory until its records change commits it, so the queues, the backlog, and the history must match the merged work before sprint 11 starts.

---

## Changes

- Add the pending history rows of both lanes, markdown-reading-b to the feature metrics and git-signs-trust to the backlog metrics
- Change the backlog by removing the five entries the sprint plan listed, folding in the eight delivery findings files, and appending the groomed entries
- Change both lane queues to the sprint-11 order, the feature queue taken from this delivery's plan so it no longer names the merged git-signs-trust and draws markdown-reading-c in
- Add the sprint-10 row to the sprints file
- Fix two backticked paths that do not exist, in a folded backlog entry and the backlog queue's batch note, so the docs lint passes
- Add the archived OpenSpec change with skip_specs set, and record the three advisory review findings for the next grooming

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings and three advisories recorded as findings
- Run the checker's fast stages, all pass, docs-lint and gates in full and the build, test, diagnose, bench, metrics, and tools stages scoped out as no code changed
- Run make spec-validate after the archive, 53 of 53 pass
- Run make docs-lint after recording the findings, all checks pass

---

## Notes

The change alters no code, test, or tool; it is a T0 delivery record outside the sprint count. The backlog entry for the git_signs promisor lazy fetch stays, since git-signs-trust listed it and the next sprint's grooming removes it as listed.
