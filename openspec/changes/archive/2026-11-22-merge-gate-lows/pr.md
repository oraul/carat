fix(workflow): make the merge gates' green line fail closed

## Summary

Makes the merger's green line fail closed when listing replace refs fails, and runs main's merge gates only after the checked-out copy has been verified against main's tree. Three security Lows on the command that judges every merge let a failed listing pass the refs/replace stop, and let a copy holding text other than main's (an object swapped back before the fsck, or a file rewritten after it) reach main's gates.

---

## Changes

- Change the green line's refs/replace stop in `.claude/workflows/deliver-change.js` to list refs/replace and origin/main together, newest name first, and pass only on origin/main's one line, so a failing for-each-ref or any replace entry stops the line before the worktree add
- Add a content check after the fsck: `git read-tree origin/main` and `git diff --quiet` in the merge-gates copy, so any tracked file whose text is not main's stops the line before main's gates run
- Change `tools/agent_guard.sh` to admit the merger's `git -C tmp/.NAME read-tree origin/main` in a worktree with no other option, refusing every other read-tree, and name the form in its header
- Correct the comment above `MERGE_GATES`, which said the fsck stops an object swapped back, and say what each step stops and what stays out of reach
- Add `tools/tools_test.sh` cases for a failing for-each-ref, an object swapped back before the fsck, a gates file rewritten after the fsck, the order of the content check, and the guard's read-tree forms, and update the pinned-fetch case for the new stop
- Document the fail-closed stop and the content check in README.md delivery step 9 and `docs/codebase-map.md` area 1
- Record the plan's backlog queue and the backlog lane's metrics history rows

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 0, none blocking
- Run every check stage through `tools/run_state.sh check` (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark comparison against main's recorded figures, pass with nothing blocking
- Run `make spec-validate` after the archive, 56 passed, 0 failed

---

## Notes

The fourth backlog heading, fork pull requests sharing the branch name in `tools/open_pr.sh`, no longer held on main: 7cbcf29 (#268) already keeps only same-repository pull requests, and its existing cases fail with the script before that commit, so this change leaves `tools/open_pr.sh` alone. A same-user process rewriting the copy between the diff and the gates' own reads is still out of reach of any shell line and is left to CI, the reviews, and branch protection, as the design records. `tools/rules.sh` is not edited.
