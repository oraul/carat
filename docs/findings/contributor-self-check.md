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
