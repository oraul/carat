### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh (metric.rework) and .claude/workflows/deliver-change.js (the in-place fix round)
- Why: finder-grep-c (retro 5) had rework 2 of 3 with every first pass 1 (check, security, quality, bench, ci); its round 2 changed only README.md and docs prose and still reran every check stage and review. Near-same as the queued `rework-review-repeat` and `review-lite-docs`: merge into them.
- Fix: count an advisory-only round apart from a blocking one and let a docs-only advisory fix stand on the previous head's check, security, and bench; accepted when a tools-test case shows a docs-only advisory fix leaving metric.rework unchanged.

### A pull request's benchmark figure can compare different builds and sources

- Location: tools/open_pr.sh (the Testing section) and the run state's us_per_key (no grep scenario figure recorded)
- Why: the finder-grep-c body (retro 6) says 25.3 ms per key (dev budget build, bench-budget log) against about 45 ms before (release, the proposal's estimate), while its implement start measured 3.2 ms against main's 12.5 ms in release on the same scenario.
- Fix: record the grep scenario figure in the run state and let the Testing section cite only recorded run-state or stage-log figures, any before figure main's at the same build and scenario; accepted when a body citing an unrecorded timing is refused.
