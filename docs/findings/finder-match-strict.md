### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh (metric.rework) and .claude/workflows/deliver-change.js (the in-place fix round)
- Why: finder-grep-c (retro 5) had rework 2 of 3 with every first pass 1 (check, security, quality, bench, ci); its round 2 changed only README.md and docs prose and still reran every check stage and review. Near-same as the queued `rework-review-repeat` and `review-lite-docs`: merge into them.
- Fix: count an advisory-only round apart from a blocking one and let a docs-only advisory fix stand on the previous head's check, security, and bench; accepted when a tools-test case shows a docs-only advisory fix leaving metric.rework unchanged.

### A pull request's benchmark figure can compare different builds and sources

- Location: tools/open_pr.sh (the Testing section) and the run state's us_per_key (no grep scenario figure recorded)
- Why: the finder-grep-c body (retro 6) says 25.3 ms per key (dev budget build, bench-budget log) against about 45 ms before (release, the proposal's estimate), while its implement start measured 3.2 ms against main's 12.5 ms in release on the same scenario.
- Fix: record the grep scenario figure in the run state and let the Testing section cite only recorded run-state or stage-log figures, any before figure main's at the same build and scenario; accepted when a body citing an unrecorded timing is refused.
### review-due no longer bounds uncounted merges
- Location: tools/run_state.sh:2235
- Why: review-due no longer caps how many merged changes go uncounted (SPRINT_EXCEPTIONS removed in #236, which came in through the merge of main). A queue edited to mark items T0, pool, beyond the sprint, or outside the 3 can keep the sprint-end security review of the combined diff from ever becoming due. Each delivery still gets its own security review. Security, Low, confidence 4.
- Fix: Bring back an upper bound so the sprint closes after at most sprint_size plus a fixed number of uncounted merges, whatever the queue text says. Add a tools_test.sh expect case where an uncounted run still trips the bound.
### review-due uncounted merges unbounded in sprint_state
- Location: tools/run_state.sh:2236
- Why: Same gap as the entry above, seen again at 040963076f86: sprint_state counts only the names not classed t0, outside, beyond, or pool, and nothing bounds how many go uncounted. Security, Low, confidence 4.
- Fix: Bring back an upper bound so the sprint closes after at most sprint_size plus a fixed number of uncounted merges, whatever the queue text says. Add a tools_test.sh expect case where an uncounted run still trips the bound.
### README summary still says fuzzy file finder
- Location: README.md:5
- Why: The summary still calls the finder a fuzzy file finder, while the plugin's class comment and docs/actions.md now describe substring or initials matching. Quality, advisory, docs currency.
- Fix: Say a file finder, as plugin.rb line 8 now does.
### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh (metric.rework) and .claude/workflows/deliver-change.js (the in-place fix round)
- Why: finder-grep-c (retro 5) had rework 2 of 3 with every first pass 1 (check, security, quality, bench, ci); its round 2 changed only README.md and docs prose and still reran every check stage and review. Near-same as the queued `rework-review-repeat` and `review-lite-docs`: merge into them.
- Fix: count an advisory-only round apart from a blocking one and let a docs-only advisory fix stand on the previous head's check, security, and bench; accepted when a tools-test case shows a docs-only advisory fix leaving metric.rework unchanged.

### A pull request's benchmark figure can compare different builds and sources

- Location: tools/open_pr.sh (the Testing section) and the run state's us_per_key (no grep scenario figure recorded)
- Why: the finder-grep-c body (retro 6) says 25.3 ms per key (dev budget build, bench-budget log) against about 45 ms before (release, the proposal's estimate), while its implement start measured 3.2 ms against main's 12.5 ms in release on the same scenario.
- Fix: record the grep scenario figure in the run state and let the Testing section cite only recorded run-state or stage-log figures, any before figure main's at the same build and scenario; accepted when a body citing an unrecorded timing is refused.
