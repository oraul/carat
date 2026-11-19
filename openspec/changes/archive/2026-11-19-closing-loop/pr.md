chore(workflow): add one closing loop for own-file advisories

## Summary

Adds one closing contributor loop to the delivery workflow: after the last review passes with no blocking finding and before packaging, a contributor start fixes the run's own-file advisories that need no new behavior. Non-blocking findings never hold a merge, so runs left about seven findings per merge in the findings files; this closes the ones the run can close and records the figures to compare findings per merge before and after.

---

## Changes

- Add the closeAdvisories step to the deliver workflow, run once a run: one contributor start in the new mode close-advisories, then the check, a quality review scoped to the closing commits, and the security review again unless the commit changed only records
- Send advisories raised by the closing review to the findings file with no second loop, and route a blocking finding there through the normal fix path within the round limit
- Skip the loop when the run has no open advisory, and hold the closing figures across a resume
- Record advisories_closed and advisories_left in the run state, and write them as two columns after weighted_phases in the metrics history
- Name the close-advisories mode in the contributor agent and its rules in docs/contributor-notes.md, and update README.md and the code map
- Add tools-test cases for the closing start with its scoped re-review and figures, the skip, the absent second loop, the security review of a code-changing commit, and the history columns
- Archive the closing-loop change, record its two non-blocking advisories in its findings file, and apply its plan and metrics history

---

## Testing

- Security review of the committed diff passed with no High, Medium, or Low finding at the final head, recorded in the run state
- Quality review passed with no blocking finding and one advisory, recorded in the findings file
- Benchmark review passed with no blocking finding
- Run the checker stages on the final implementation commit, all passed, including tools-test, test-run, diagnose, and bench-budget
- Run make gates, make docs-lint, and make spec-validate, all pass (54 items validated)

---

## Notes

The queue's exception line stays after delivery, since the exception allowed this change beyond the sprint size. The figures of a run resumed during the closing re-review are a lower bound, recorded in the findings file. Nothing in tools/rules.sh changed.
