fix(run-state): record the merged commit with the merge phase

## Summary

Recording a change's merge phase now also records its merged commit, and the sprint-review check names any run state that holds a merge phase without one instead of leaving it out of the sprint count. A delivery once held its merge phase with the merged commit empty, so the sprint count skipped it without a word until the main session set the commit by hand.

---

## Changes

- Change `phase CHANGE merge` in `tools/run_state.sh` to write the merged commit, once checked on main, before the merge phase when none is recorded, and to refuse the phase, writing nothing, when a recorded merged commit names another commit
- Add `merge_unrecorded` to `tools/run_state.sh`, listing each run state with a valid merge phase but no merged commit, no history row, and not a review run
- Change `review-due` to report `not due` naming each such run state and the command that records its commit, after the line of a sprint plan that already waits
- Add tools-test cases for the merged commit written with both forms of the merge phase, the refusal on a differing recorded commit, and the review-due line, including the run states it leaves out and its order after the waiting plan's line
- Document the merge record and the new review-due line in the README pipeline paragraph and the code map's `tools/run_state.sh` entry
- Archive the OpenSpec change with its proposal, design, and tasks, with no spec delta, and record the backlog lane's plan, metrics history, and one advisory finding

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings and one advisory, recorded in the change's findings file
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark review, pass with no blocking findings
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The merger's step 7 still runs its own set of the merged commit, which now agrees with or precedes what the merge phase writes; making the merge phase the single writer is left for a follow-up recorded in the findings file. No spec changes, since the change alters only delivery tooling, and tools/rules.sh is not edited.
