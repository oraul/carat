### The merge gates' fsck misses an object swapped back after the worktree add (security Low (5))
- Location: .claude/workflows/deliver-change.js:595 (the comment above the green line) and the archived ci-trust-gaps design.md
- Why: the comment and design say an fsck after the worktree add still catches an object swapped back in between, which is backwards: a process left running by branch code can plant the loose object before the add and restore main's real content before the fsck, so the add writes the planted tools/gates.sh into tmp/.merge-gates and fsck passes; such a process could also write the worktree directly, so this is defence in depth (security Low (5), and the quality review's advisory at the same line).
- Fix: correct the comment and the design: fsck catches an object still planted, not one swapped back; to close the gap, verify the checked-out files against main's tree after the fsck (hash each with git hash-object against git ls-tree origin/main under --no-replace-objects), or fsck both before and after the add, and say which window remains.
### The merge gates' worktree file can be rewritten on disk after the fsck (security Low (5))
- Location: .claude/workflows/deliver-change.js:650 (the green line's sh tmp/.merge-gates/tools/gates.sh merge)
- Why: a process left running by branch code, such as a background job of a check or the other lane's checks, can overwrite tmp/.lane-CHANGE/tmp/.merge-gates/tools/gates.sh between the worktree add and the run, which no object check sees; the fsck now between those steps (2 s warm, 47 s cold) widens that existing window.
- Fix: run main's gates from the verified store instead of the checked-out file, for example git --no-replace-objects cat-file blob origin/main:tools/gates.sh piped to sh -s merge after the fsck, or compare the checked-out tools/ against git ls-tree blob ids in the same command right before the run; record that a lingering branch process is outside the merge gates' threat model.
### The planted-object case pins fsck's exact exit status (missing-test robustness)
- Location: tools/tools_test.sh:3441
- Why: the case expects exit status 3, the OR of git's internal fsck error bits (object plus reachability), which another git version may report differently, so the case can fail with the gate still working.
- Fix: assert that the line fails and its output names the mismatch, without the exact status.
### The unpinned-git case proves the add, not that the planted gates ran (missing test)
- Location: tools/tools_test.sh:157 (the case an unpinned git would run the replaced gates past fsck)
- Why: the case sends the line's output to /dev/null and only cats the checked-out gates.sh, so it proves the worktree add followed the replace ref, not that fsck passed and the planted gates ran.
- Fix: assert the line's own output, sh -c "$2" 2>/dev/null expecting ^planted$, instead of the cat.
