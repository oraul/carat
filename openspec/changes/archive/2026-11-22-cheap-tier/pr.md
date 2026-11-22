chore(pipeline): run bookkeeping starts on a cheap runner agent

## Summary

Moves the delivery and sprint workflows' bookkeeping starts to a new runner agent on the cheapest tier at low effort, stops the merger from deleting the remote branch, and makes the merged record refuse a squash commit whose last line is not exactly the co-author trailer. The mechanical resume, record, and sprint bookkeeping starts cost about 0.3M weighted tokens a delivery and 0.5M a sprint close on the session's model, the remote delete was refused on #300 because the repository deletes a merged branch itself, and #307's squash commit ended with the trailer followed by a stray double quote that nothing in the merge phase noticed.

---

## Changes

- Add the runner agent, a Bash-only agent file on the cheapest tier whose hook runs a new runner profile of the agent guard
- Add the guard's runner profile, which allows only the resume recipe's commands and the run state records the workflow writes, and refuses edits, pushes, the gates script, and the close profile's finding notes
- Change the delivery workflow's resume and record starts to run as the runner, their calibration moving from session/low to agent/low
- Change sprint planning's due, record, and records-merged starts to run as the runner at low effort, leaving the notes and skeptic notes starts on the quality reviewer's read profile
- Remove the merger's remote branch delete and the guard's permission for it, keeping the local branch and worktree cleanup
- Change the run state's merged record to refuse a squash commit whose last non-blank line is not exactly the co-author trailer, without rewriting history on main
- Add tools-test cases for each start's tier and agent, the runner profile's allowed and refused commands, the absent remote delete, and a stray character after the trailer refused by both the merged record and the merge tool's hook
- Document the runner in CLAUDE.md, the README, and the calibration move with its keep rule in docs/goals.md

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the check stages at the implementation head (docs-lint, dev-build, test-build, test-run, gates, bench-budget, diagnose, tools-test, metrics), all pass
- Run the benchmark review against main's recorded figures, pass with nothing blocking
- Run make spec-validate after archiving the change, all 56 items pass

---

## Notes

The runner's keep rule is in docs/goals.md: the move is kept when the first passes and the rework plus self_fix over the next 5 non-records rows are no worse, otherwise the planner queues its revert. The trailer check applies to merges from now on; the stray character on #307's squash commit stays in history. The change does not edit tools/rules.sh.
