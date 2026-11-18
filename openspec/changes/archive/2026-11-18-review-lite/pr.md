chore(pipeline): settle advisory-only rounds that change only records

## Summary

Settles an advisory-only fix round whose fix changed only records-only paths: the delivery workflow runs no check, no security review, and no benchmark at its head, records the skip in the run state, and reruns only the quality review over the changed commits. A round answering only advisories reran the whole verification even when no code changed, as when sign-colors spent a second rework round with 0 blocking findings and 71,651 output tokens after its first check pass. A blocking finding, a security finding offered in place, or any change outside the records-only paths keeps the full round, so the security review is never skipped when code changed.

---

## Changes

- Change the delivery workflow so an advisory-only round with nothing blocking and no security finding offered in place asks the checker to settle from the commit where this start's check, security review, and benchmark passed, skipping them only on a settled line naming that commit and the head, and noting the skip as a settled-round entry in the run state.
- Add the run_state.sh settled command, which exits 0 only when the tracked tree is clean, the commit is an ancestor of the head, and every file changed since it matches the records-only pattern the merge gates already settle a pass across, and otherwise names the files.
- Keep a settled round's state to its own head, so a later full round in the same start is packaged with the check and security review at the commit where they actually ran.
- Change the checker's run start to run the settle line first in such a round and the guard's read profile to allow it.
- Add tools-test cases for a records-only round settling with the skip recorded, a round with code or a blocking finding running in full, and the settled command's refusals.
- Document the settled round in the README pipeline step, the code map's run_state.sh entry, and the in-place re-review rule of the goals.
- Record the lane's plan, the metrics history, and this change's non-blocking review findings.

---

## Testing

- Security review of the committed diff at 9b3247f66fa9, pass with 0 high, 0 medium, and 0 low findings, 0 blocking.
- Quality review at 9b3247f66fa9, pass with 0 blocking and 2 advisory findings, recorded in the change's findings file.
- Run the checker's fast stages at 9b3247f66fa9 (diagnose, docs-lint, dev-build, test-build, bench-budget, tools-test, gates, test-run, metrics), all pass.
- Benchmark review at 9b3247f66fa9, pass with no allocation or round regression.
- Run make spec-validate after archiving the change, 54 passed and 0 failed.

---

## Notes

The brief's docs, comments, and spec text are narrowed to the records-only paths the merge gates already accept, since the gates refuse a pass after any other change; a round editing README.md, docs/architecture.md, a carat comment, or a test keeps the full round, and widening that is the queued review-lite-docs change, which edits tools/rules.sh and tools/gates.sh, neither touched here. This is a pipeline speedup under the user-approved exception of Sprint 19 in docs/queue-backlog.md, and no file of the feature lane is touched.
