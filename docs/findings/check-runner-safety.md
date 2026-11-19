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

### A check stage can forge notes and closing phases in its own run state
- Location: `tools/run_state.sh`, `state_view`.
- Why: so that the close of a workflow that stops while its detached check runs leaves the rejoined check passing, the run-state comparison now also leaves out the notes (`note.*`) and the phases the close records (`phase.plan`, `implement`, `package`, `ci`, `merge`, `retro`, `report`), so a stage that writes its own change's run state by an absolute path during a check can plant such a note or phase and the check still passes; `phase.check`, `review.*`, `stage.*`, `merged`, and the measurements stay compared.
- Fix: log each record a caller's command (`phase`, `note`, `metric`, `usage`, `tokens`) writes while a check runs, outside any path a stage can write, and accept a changed note, phase, or figure only when that log names it; any other difference fails the check like the other run-state differences.

### Security: a lane check's scan leaves the main checkout and the common git directory's refs and info out (security Medium (7), still present at package)
- Location: tools/run_state.sh:1039 escaped_paths (reported at :1025, :1026, and :1039 across the review passes, code unchanged since 8071a6b0ff9a)
- Why: every delivery runs in a lane worktree, and the scan covers only the lane's own tree, its git directory, and the common directory's hooks/, config.worktree, and config; a stage that learns the main checkout's path from the build/pipeline link or from git rev-parse --git-common-dir can rewrite the main checkout's tools/agent_guard.sh, .claude/settings.json, or tools/gates.sh, or another lane's refs/heads/* or info/ in the common directory, and the check still passes. Merges the four passes' reports of this gap, including the one asking that it be recorded.
- Fix: when git_dir differs from common_dir, also scan the main checkout's working tree (the parent of common_dir) with the same prunes, and scan common_dir/info and the other lanes' refs, or compare them with the writes the runners log, allowing for concurrent lanes and the main session.

### Security: a stage's detached child can write after the escape scan (security Low (6), still present at package)
- Location: tools/run_state.sh:738 stage_launch (reported at :731 and :738 across the review passes, code unchanged)
- Why: stage_launch waits only for the stage's direct child and escaped_paths runs once, after the stages pass, so a stage that starts a setsid or nohup child sleeping past the scan can then write the shared toolchain, a hook, or a tracked file, and the next check or delivery runs on what it left. Merges the four passes' reports of this gap, including the one asking that it be recorded.
- Fix: run each stage in its own session or process group and kill that group before escaped_paths runs, or repeat the scan of the shared toolchain and hooks at the start of each check from a mark kept since the last check ended.

### Security: a stage can forge its own run state's metric lines during a check (security Low (6), still present at package)
- Location: tools/run_state.sh:1007 state_view (reported at :1002, :1006, and :1007 across the review passes)
- Why: state_view leaves every metric.* line out of the run-state comparison except the measurements (allocs, rounds, us, analysis_ms), wider than the earlier list that mirrored the checker's metricLine; a stage writing its own change's run state by an absolute path can forge metric.phase.*, first.*, calib.*, estimate, rework, planned, total_tokens, wall_min, start.*, weighted.*, or counted, which feed the first-pass rates, the token budget, and the history rows, and the check still passes. read_key takes only a line's first key and trusted_state drops multi-key lines, so no review.* or phase.* record can be planted this way. Merges the four passes' reports, including the Low (5) one on the narrower list and the one noting a finding listed as fixed in place is still present.
- Fix: at escape_mark, snapshot the metric.* lines; after the stages, accept a changed or new metric.* value only when a command the runner's caller ran (metric, usage, tokens) logged writing it, the log kept where no stage can write (for example under build/pipeline beside the run state); any other metric.* difference fails the check.

### Security: a stage can plant notes and closing phases in its own run state during a check (security Low (6), still present at package)
- Location: tools/run_state.sh:1007 state_view with CLOSE_PHASES (reported at :1006 and :1007; the move of the list into CLOSE_PHASES matches the same lines and adds no injection)
- Why: state_view leaves every note.* line and the closing phases (plan, implement, package, ci, merge, retro, report) out of the run-state comparison, so a stage writing its own run state by an absolute path can plant a forged note, or a closing phase at a real commit, and the check still passes: that can mislead the planner, make a resume skip a phase, or make an unclosed run look closed through phase.retro. trusted_state still keeps review.*, phase.check, and merged compared, the merger checks CI live, and the merge gate reads the review records. Merges both passes' reports.
- Fix: while a check runs, have each caller command that writes a record (phase, note, metric, usage, tokens) log the key and value it wrote, somewhere no stage can write (for example beside the run state under build/pipeline with the runner's pid), and in state_unexpected accept a changed or new note.*, closing phase.*, or metric.* line only when that log names it.
none
