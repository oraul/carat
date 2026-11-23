chore(workflow): skip the benchmark when no Ruby code changed

## Summary

Skips the Benchmark phase's agent and records the bench review as passed when a change's committed diff touches no Ruby code, so a docs-and-tools-only change no longer loses a round to allocation noise. A change that edits no Ruby code cannot change allocations or rounds, yet the gate compared them, and an earlier coverage change lost a fix round to grep noise of 685.3 against 685.0. The check clone also now receives a read-only copy of the plan's sprint marker and groom lines so a records carrier passes the gates stage there as it does in the lane.

---

## Changes

- Add a ruby line to the lane facts that reads yes when a path changed from the merge base to HEAD lies under carat, bin, bench, config, or tools/spinel or is carat.rb, the Makefile, or tools/metrics.sh, no otherwise, and unknown without a base or when git diff fails.
- Change the Benchmark phase in the delivery workflow to record the bench review as passed at the head with a note naming the reason (no Ruby code changed) and start no agent, only when the check passed at the head, the lane is clean there, and the fact reads no; any other reading keeps today's gate and the merge gates still read review.bench passed at the head.
- Add a clone_plan step to the check runner that copies the plan's sprint marker and groom.txt into the check clone as regular files, read there and never written back, so a records carrier's groomed findings are proven in the clone.
- Add tools-test cases for the ruby line over each path class, the strict parse, a docs-and-tools-only diff recording the bench review with no agent start, a Ruby-touching diff keeping the gate, and a carrier head passing the gates stage in the check clone.
- Document the skip in README.md and the lane facts and check runner entries of docs/codebase-map.md.
- Apply the sprint plan: append the lane's metrics rows, the sprint row, both lane queues, and the groomed backlog, and reword two groomed backlog lines so no scheme text enters history.
- Archive the OpenSpec change bench-skip-nonruby with its proposal, design, and tasks.

---

## Testing

- Run the fast stages with the run-state check at the head, all pass: docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics.
- Run the security review of the committed diff at the head, passed with no High, Medium, or Low findings.
- Run the benchmark review at the head, passed with no blocking finding.
- Run the quality review of the diff, two findings added and both recorded in the findings file.

---

## Notes

The user decided on 2026-11-23 to skip the benchmark when no Ruby code changes, and to widen this change to the check clone's plan copy. No edit of tools/rules.sh. Test files are not treated as Ruby code for the skip because the benchmark runs bench, not tests. A tolerance or rerun for allocation noise in Ruby changes is left out of scope.
