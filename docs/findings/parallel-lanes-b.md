### Lane worktree trusts a branch-controlled build/pipeline
- Location: tools/run_state.sh:2347 (lane_open), the green line of .claude/workflows/deliver-change.js
- Why: security Medium (5): a branch that force-adds build/pipeline, as a directory or a symlink, stops lane-open from linking the lane to the main checkout's run state, so the merge gates running inside the lane read branch-controlled stage records, push counts, and body file instead of the workflow's own records.
- Fix: in lane_open refuse when git -C "$dir" ls-files lists anything under a LANE_LINKS path, or when "$dir/$l" exists but is not a symlink to "$top/$l"; pass gates.sh merge an absolute RUN_STATE_DIR and STAGE_DIR of the main checkout and read the body file from its absolute path.

### Merger's lane-close and contributor's merge-main accept any change name
- Location: tools/agent_guard.sh:600-601
- Why: security Low (4): the merger profile admits run_state.sh lane-close with any arguments, unlike push and set beside it, so a misled or prompt-injected merger could force-remove another running delivery's worktree and lose its uncommitted work; merge-main is admitted the same way.
- Fix: require [ $# -eq 2 ] and matches "$2" "$CHANGE_NAME" for both, as contributor:push does, with one refusing guard case each in tools/tools_test.sh.

### merge_main runs git merge with global configuration and hooks
- Location: tools/run_state.sh:2391 (merge_main)
- Why: security Low (3): a plain git merge reads global and system configuration and runs hooks, both writable by branch code the checks run, which is why the fetches and the merge-gates worktree use pinned git.
- Fix: run the merge through pinned_git (GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1, -c core.hooksPath=/dev/null), keeping the core.attributesFile and identity -c options.

### merge_main hides a merge failure that is not a conflict
- Location: tools/run_state.sh:2397 (merge_main)
- Why: correctness: git merge's output goes to /dev/null, so a failure that is not a conflict (an untracked file it would overwrite, a missing ref) reports conflicts with no file named, and the silent git merge --abort then fails.
- Fix: keep git's stderr and print it when no file is unmerged, aborting only when a merge is in progress.

### Concurrent lanes race on the shared origin/main ref lock
- Location: tools/run_state.sh:2388 (merge_main) and the green line's fetch
- Why: correctness: two lanes share one .git and both fetch +refs/heads/main:refs/remotes/origin/main, so concurrent deliveries can fail on the ref lock.
- Fix: retry the fetch once on failure, or fetch into a per-lane ref such as refs/lanes/<change>/main.

### lane_open and lane_close remove a worktree by different steps
- Location: tools/run_state.sh:2332 (lane_open), :2366 (lane_close)
- Why: correctness: lane_open removes a replaced run's worktree directly while lane_close removes the toolchain links first so no removal can reach their targets; the two paths can diverge in safety.
- Fix: share one lane_remove helper (links first, then git worktree remove --force) from both.

### MERGE_MAIN tells a continuation start to merge over a dirty tree
- Location: .claude/workflows/deliver-change.js:702, tools/run_state.sh:2385
- Why: correctness: every implement and fix start is told to run merge-main first, but merge_main dies on a dirty tracked tree, so a continuation over uncommitted work exits 1 before it starts.
- Fix: say to run it when the tracked tree is clean, else after the next commit.

### Lane and merge-main refusals have no tools-test case
- Location: tools/tools_test.sh:1593; tools/run_state.sh:2330, :2365, :2383-2385
- Why: missing test: no case covers lane-open or lane-close over a non-worktree tmp/.lane-CHANGE, nor merge-main on a detached HEAD, on main, or with a dirty tracked tree.
- Fix: add one refusing expect case each.
