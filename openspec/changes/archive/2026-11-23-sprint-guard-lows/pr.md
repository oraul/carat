fix(pipeline): bind the guard and gate scripts to committed content

## Summary

Tightens the pipeline's guard and gate scripts so the merger's lane-close and the contributor's merge-main bind to the run's own change, the records-only gate reads the sprint row and history rows from committed content, and a rerun of the sprint review no longer records the planner's quality notes twice. These close queued security Lows that a misled agent could reach, and the defect of a /sprint rerun recording the planner's quality notes twice.

---

## Changes

- Change the guard in tools/agent_guard.sh so lane-close and merge-main take exactly one change name, lane-close only for the change whose run state is a regular file recording the pushed head as gated, and merge-main only after a cd into that change's lane worktree.
- Change groom_row in tools/gates.sh to compare the appended sprint row with groom's row byte for byte as files, so a trailing blank line no longer passes.
- Change groom_row to refuse a branch whose lane history files had an earlier row edited, not only appended to, after the security review's commit.
- Add the sprint-row COMMIT committed form to tools/run_state.sh, which reads the history rows from the committed content with git show instead of the working tree.
- Change add_note in tools/run_state.sh to drop an exact repeat of a quality note, as it already does for a security note.
- Add tools-test cases in tools/tools_test.sh that fail before each fix: the guard refusals, the blank line after groom's row, an edited earlier history row, a working-tree edit of the history rows, the repeated quality note, and the usage case of sprint-row.
- Document the sprint-row words in docs/codebase-map.md and record in the findings file the headings whose fix this change does not make, with the reason.

---

## Testing

- Run the fast stages with the run state check at the reviewed head, all stages pass, including tools-test, test-run, diagnose, bench-budget, and metrics.
- Run the security review of the committed diff at the reviewed head, pass with no High, Medium, or Low findings.
- Run the benchmark check at the reviewed head, pass with no blocking finding.
- Run make spec-validate after archiving, 56 items pass.
- Run make gates and make docs-lint at the packaged head, both pass.

---

## Notes

The RISKY_CONFIG pager keys are not changed here because they edit tools/rules.sh, the merge gate's rules, which goes first and alone; they are recorded for their own change. The notes prompt's finding text, the package step's post-review prose edit, the budget line's output share, the spec_validate.sh command variable, path_of, and the untracked sprint marker are recorded in the findings file with their reasons. The Security line suffix and Sweep line are already tested by an earlier merged change.
