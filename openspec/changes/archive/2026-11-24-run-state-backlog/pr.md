fix(tools): close the run_state.sh backlog entries

## Summary

Works through the 200 open backlog entries of tools/run_state.sh and closes 139 of them, each by a fix, by evidence that the base already fixed it or no longer holds the code, or by merging it into the entry it repeats; the other 61 are recorded as not fixed with their reasons. The entries were the largest group of the backlog, 36 of them security including 2 Medium, and the user asked for them to be taken together; the check sandbox, groom proof, and workflow-bound entries that need their own design are left to their own changes.

---

## Changes

- Change the check sandbox so stages run with a throwaway HOME in the check clone and no XDG configuration, the escape scan also reads the XDG git configuration, the shell startup files, and the agent hooks' settings, and the main checkout's paths and files are compared NUL-separated
- Change the escape scan so a link planted in the build directory stays out of the carry and the next clone, every build log of the main checkout changed during a check is reported like any other file, and only a path in LANE_WRITTEN gets an escaped verdict
- Change the compile cache so a pass is keyed by the code key and the make command, the dev-build code key leaves out test/ and bench/, and a compile stage that passed while the check stopped is noted as compiled
- Change lane-open, lane-close, and merge-main so lane-open reads origin's refs first and validates the branch, both lane commands remove a worktree through one helper, and a merge that fails with no conflicted file shows git's own message
- Change history, groom, and plan-apply so the fold drops none placeholder lines, references to removed findings files name the removed file, plan entries are appended once, history names the lane file it appended to, and a stale plan is refused
- Change squash_commit and merged_at to judge against the base only, and make moved rerun the reviews when a merge kept the change's side of a file main also edited
- Change the plan-needed line to name every failing review and the later passing review condition, and refactor the repeated review-run, commit, key, and budget helpers into single copies, with the path-scope helpers and their stage-list comments only reordered above main_stages
- Add a tools-test case per fixed behavior, failing before the fix, with failing-stage or refusal cases for the security entries; the fixes to the run state header text and to comments have no case
- Document the new refusals in the script header, reword the run_state.sh bullet of CLAUDE.md, and update its code map entry for CHECK_BIN, stage_key, and the renamed BEYOND_SPRINT_MARK
- Record each entry's outcome (fixed, already fixed, gone, merged, or not fixed with the reason) under its heading in docs/findings/run-state-backlog.md

---

## Testing

- Run the check stages at the implementation head, all pass
- Run the security review of the committed diff, no High, Medium, or Low finding
- Run the benchmark review, no blocking finding
- Run the quality review of the diff, 2 advisories added, none fixed in place, both recorded in the findings file
- Run make spec-validate after archiving the change, all items pass

---

## Notes

An entry whose fix needs an edit of tools/rules.sh is not fixed here, since the merge gate reads that file and an edit of it goes first, alone, and a security entry needing an operating-system sandbox is recorded as not fixed with its reason. The remaining check sandbox, groom proof, and workflow-bound entries are recorded as not fixed for their own changes. The sprint 32 groom is carried by this change with this change's own findings file left unfolded; the plan-apply step refused the plan as older than the branch's queue, so the groomed queue stands.
