### A carried review trusts a moved record written by the branch's own run_state.sh
- Location: tools/run_state.sh:2806 (carried_backed)
- Why: security Low (4): the checker runs the branch's copy of tools/run_state.sh in the lane worktree, so a main-moved merge commit that edited the moved function could write the moved record although files changed after the review, carrying the earlier reviews to unreviewed code; not new, since before this change the moved line alone carried, and branch-controlled scripts already write the run state.
- Fix: in the review command's carried=1 path, run from the main checkout's trusted copy, compute the REVIEWED, CURRENT, and MOVED name diffs again (or call moved_change from that copy) instead of only reading the stored record, or refuse to carry whenever the diff from the reviewed commit to HEAD touches tools/run_state.sh or tools/agent_guard.sh.
### moved carries when the merge keeps the change's side of a file main also edited
- Location: tools/run_state.sh:2783 (moved_change)
- Why: correctness: a file both the change and main edited, merged keeping the change's text (a conflict resolved with checkout --ours), is in REVIEWED and CURRENT but not in MOVED, so HEAD reverts main's landed fix in that file and both reviews carry, the class of revert this change closed for main-only files (reproduced: moved names empty, git diff main HEAD shows -FIX +CHANGE).
- Fix: also read the names of git diff OLD_BASE NEW_BASE, its status checked, and run the reviews again when any of them outside RECORDS_RE is in REVIEWED, with a tools_test case merging a conflict resolved --ours.
### No case refuses a carried review when the moved record names another head
- Location: tools/tools_test.sh:860
- Why: missing test: the head check of the moved record behind a carried review has no case proving a record from an earlier head is refused.
- Fix: run moved to exit 0 at one head, commit, and expect review carried=1 at the new head refused.
### moved writes the run state yet stays a read-profile verb for agents
- Location: tools/agent_guard.sh:612
- Why: security: moved now writes the run state (drop_key, write_key) and its record gates the review record the merge gate reads, yet the checker and reviewers may run it with any commit.
- Fix: in a follow-up (the guard runs from main), restrict moved's COMMIT for agents or move the record's write out of the agent-run command, and say in the guard header that moved writes.
