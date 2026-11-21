### self_fix has no history column
- Location: tools/run_state.sh HEADER and history_row; .claude/workflows/deliver-change.js metricLine
- Why: the keep rules of docs/goals.md read rework plus self_fix, but self_fix lives only in the run state (metric.self_fix), so the planner comparing history rows cannot see the rework a contributor fixed in its own session; adding a column means rewriting line 1 and padding every row of both lane histories, and this change may not touch the feature lane's docs/metrics-feature.tsv.
- Fix: a sprint records change appends a self_fix column 25 to HEADER, pads both lane files with -, writes metric.self_fix in history_row, and points docs/goals.md at the column.

### check_runs is the contributor's own count
- Location: .claude/workflows/deliver-change.js extraRuns and the WORK field check_runs
- Why: self_fix sums the check runs the contributor reports; a start that misreports them skews the rework comparison, and nothing compares the count with the runner's verdicts.
- Fix: have tools/run_state.sh count the check runs per change (a counter the runner bumps at each start, never an agent) and let the workflow read that figure instead of the reported one.

### Backlog items check-at-head and self-check-drop
- Location: docs/queue-backlog.md Pool 11 (check-at-head, self-check-drop), folded by the plan of contributor-self-check
- Why: this change settles check-at-head as far as its brief names it: the checker's check backs the head the contributor's own passing check recorded (backedCommit), so the stages passed there are skipped; self-check-drop's text could not be read during the delivery (no agent reads the backlog), so it is not named as settled and is kept here to come back.
- Fix: the sprint planner compares self-check-drop's entry with this change's diff and either closes it with this change as evidence or queues what is left.

### security Low (6): the checker trusts stage records the contributor can write itself
- Location: .claude/workflows/deliver-change.js:970 and :974 (claimFrom and backedCommit), tools/run_state.sh stage records (comments at lines 150-170, 339-349, and 643-651)
- Why: claimFrom and backedCommit back the head on the contributor's own reported pass, so the checker skips every stage with a passing stage record at that head. A contributor misled by text in the tree could edit tools/run_state.sh or a Makefile recipe in its working tree without committing, run `sh tools/run_state.sh check <change>` so the edited runner writes passing stage records at HEAD into build/pipeline/<change>.json, then restore the file with git restore; the base..HEAD diff still leaves tools/ untouched, so lane_facts reports machinery no and the checker skips the forged stages. Reported twice by the security review: the second pass found the comments (tools/run_state.sh 150-170 and 643-651, deliver-change.js 965-972, the design's Risks) now state this trust correctly, so the false claim is gone, but the behavior is unchanged. Impact is limited: CI reruns docs-lint, the builds, test-run, bench-budget, metrics, and tools-test, and main's merge gates rerun gates, which leaves diagnose resting on the contributor session's trust. Before this change, records at HEAD counted only when HEAD was the phase.check the workflow recorded.
- Fix: Stop trusting records an agent could have forged while keeping the speed-up: either the runner registers each run (its pid, start time, and HEAD) in a place outside the project the contributor's guard cannot reach, and the checker verifies it before skipping a stage; or a backed head skips only stages CI also runs, and diagnose and gates always rerun. Also widen the machinery test to the working tree at check time and to every commit since base, not only the base..HEAD diff.
none
