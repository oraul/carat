chore(pipeline): run each delivery in its own worktree

## Summary

Runs each delivery in its own git worktree under the hidden tmp/.lane-CHANGE, sharing the main checkout's toolchain, compile cache, run state, and stage logs, and merges a moved main into the branch while it runs. Both lanes shared one working tree, so a feature delivery and a backlog delivery could not run at once.

---

## Changes

- Add run_state.sh lane-open, which makes or keeps the change's worktree on its branch from origin/main, replaces one on another branch, and links the main checkout's toolchain, build records, and cache into it
- Add run_state.sh lane-close, which removes the worktree after the merge, its links first so no removal reaches their targets
- Add run_state.sh merge-main, which merges a moved main into the branch with a trailer-carrying commit, never a rebase or force-push, the lane metrics, findings, and sprint files merging by union so both sides' rows are kept
- Change the delivery workflow so the resume opens the lane, every agent start runs its commands in the worktree, each implement or fix start merges main first, and the merger's green line runs in the lane so two deliveries never share a merge-gates path
- Change agent_guard.sh to admit the contributor's merge-main and the merger's lane-close, and the contributor and merger agents to name them
- Add tools-test cases for a worktree under the hidden tmp/ directory sharing the toolchain and removed after the merge, two lanes' records merging by appended rows only, and distinct merge-gates paths for two concurrent deliveries
- Document the worktrees and the one-feature-lane and one-backlog-lane concurrency rule in the README and the codebase map
- Apply the user's queue decisions: the Sprint 10 exception for this change, lsp-incremental-sync at the head of the backlog pool for Sprint 11, and planner-split-rule after it
- Add the merged parallel-lanes row to the backlog metrics history and this change's findings file

---

## Testing

- Security review of the committed diff, pass with high 0, medium 0, low 0, blocking 0
- Quality review, pass with blocking 0 and 9 advisories, the correctness and missing-test ones recorded in the findings file
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass, tools-test in 94 s
- Run make spec-validate after the archive, 53 passed, 0 failed
- Run make docs-lint after the queue edits, pass with the lane queues at their byte budget

---

## Notes

CLAUDE.md is unchanged: its Agents section (the Sprints, Backlog, and Run state bullets) still needs the worktree and concurrency wording, which the archived design.md drafts and leaves to the user to apply in its own approved change. The lane worktree is tmp/.lane-CHANGE rather than a tmp/.lanes directory, so each lane's path stays one hidden directory. The security Medium (5) on a branch-controlled build/pipeline in the lane is below the blocking confidence and is recorded in the findings file with its fix. The dead mergeGatesDir helper in the workflow was dropped from the findings as a style advisory, and the codebase map's lane sentence was moved after the write_key clause.
