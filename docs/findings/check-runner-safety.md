### A check stage can forge its runner's job status files
- Location: `tools/run_state.sh`, `check_stages` (`job_dir=${check_root%/repo}/jobs`), `stage_launch`, `stages_reap`
- Why: the job files sit beside the clone (`../jobs/STAGE.status`), so a stage can write a passing status for itself or a stage still running before the runner reads it, and the runner records a pass it never saw; `escaped_paths` does not scan them, since the runner writes them during the check.
- Fix: keep the job directory under the delivery clone's `build/stages/<change>/`, outside every path a stage is handed, or have each job report its status through a pipe the runner holds instead of a file.
### Shared state a check stage can still write without failing the check
- Location: `tools/run_state.sh`, `escaped_paths`: `build/pipeline` but the change's own run state (other changes' run states, `build/pipeline/compiled`), `build/stages`, `build/plan`, `build/spinel-cache`, and `tools/run_state.sh` itself
- Why: concurrent lanes and the runner write these during a check, so they are not compared; a stage can forge another lane's run state, a compile record that makes a later check skip a compile stage, or a cache object, or edit the runner while it reads its own script.
- Fix: run the stages under an operating-system sandbox (a separate user or a read-only bind of the delivery clone), or, without one, compare the compile records and the other run states by the writes the runners log.

### A check in a lane does not scan the main checkout or the common directory's refs and info
- Location: tools/run_state.sh, escaped_paths (security Medium (7))
- Why: every delivery runs in a lane worktree, and escaped_paths scans only the lane's tree, its own git directory, and the common directory's hooks/, config.worktree, and config. A stage that learns the main checkout's path (the build/pipeline link, git rev-parse --git-common-dir) can rewrite its tools/agent_guard.sh, .claude/settings.json, or tools/gates.sh, or another lane's refs/heads/* or info/ in the common directory, and the check still passes.
- Fix: when git_dir differs from common_dir, also scan the main checkout's working tree (the parent of common_dir) with the same prunes, and scan common_dir/info and the refs of other lanes, or compare them against the writes the runners log; mind concurrent lanes and the main session writing the main checkout.

### A stage's detached child can write after the scan
- Location: tools/run_state.sh:731, stage_launch, and escaped_paths (security Low (6))
- Why: stage_launch waits only for the stage's direct child, and escaped_paths runs once, after the stages pass. A stage that starts a detached child (setsid or nohup) sleeping until the scan passed can then write the shared toolchain, a hook, or a tracked file, so the next check or delivery runs on what it left.
- Fix: run each stage in its own session or process group and kill that group before escaped_paths runs, or repeat the scan of the shared toolchain and hooks at the start of each check from a mark kept since the last check's end.

### The checker's own figures stay writable by a stage during a check
- Location: tools/run_state.sh, state_view (security Low (6), narrowed)
- Why: state_view now leaves out only the figures the checker's line writes (the names of the workflow's metricLine), so a measurement a stage forges fails the check; but a stage can still rewrite metric.first.*, metric.estimate, or another of those names in its change's run state by an absolute path, and they feed the first-pass rates, the budget, and the history rows. The list also has to follow metricLine: a new name there fails a rejoined check until it is added.
- Fix: snapshot those metric lines at escape_mark and accept only the values the rejoining checker's metric command logs that it wrote, the log kept where a stage cannot write it.

### Correction: an edit of tools/run_state.sh by a stage is listed by the scan
- Location: docs/findings/check-runner-safety.md, the entry listing tools/run_state.sh among the paths a stage can write without failing the check (quality advisory)
- Why: escaped_paths scans the delivery clone's tools/ (only tmp/, .git, and four build/ directories are pruned), so such an edit is listed; the narrower risk is an edit that changes the runner's behavior before the running shell reaches escaped_paths, since sh reads the script as it runs.
- Fix: read that entry with this narrower risk; have the runner run from a copy of the script made before the stages start, so an edit of the delivery clone's copy cannot change the running check.

### The run-state comparison now leaves out every figure but the measurements (security Low (5), residual widened)
- Location: tools/run_state.sh `state_view`, the filter of the run-state comparison after a check.
- Why: so the figures /deliver's usage and tokens write while a detached check runs leave a rejoined check passing, the comparison now leaves out every `metric.*` line but the measurements (`allocs.*`, `rounds.*`, `us.*`, `analysis_ms.*`); a stage can therefore forge, by an absolute path, not only the checker line's figures (first-pass rates, the estimate, rework) but `metric.total_tokens`, `metric.wall_min`, `metric.start.*`, `metric.weighted.*`, and `metric.counted`, which feed the token budget and the history rows, and the check passes.
- Fix: as for the residual already recorded: at `escape_mark` snapshot the `metric.*` lines and accept a changed one only when a command the runner's caller ran (metric, usage, tokens) logged writing it, the log kept outside every path a stage can write.
