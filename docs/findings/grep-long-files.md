### tools-test cannot exercise bench/run.sh
- Location: tools/rules.sh:97 (TOOLS_RE), bench/run.sh
- Why: a tools-test case that reads bench/run.sh fails the check that TOOLS_RE covers every path tools-test reads, so the benchmark runner's per-key arithmetic and its budget mode have no test; grep-long-files kept the grep key counts in tools/metrics.sh for that reason.
- Fix: add bench/run.sh to TOOLS_RE in its own change (an edit of the merge gate's rules goes first, alone), then add tools-test cases over a fake benchmark binary for per_key and --budget.

### The grep scenario runs twice in the fast stages
- Location: Makefile:387 (bench-budget), tools/metrics.sh (measure)
- Why: make bench-budget prints the grep scenario's figures and make metrics now measures the same scenario at the same keys, so each check spends the grep runs over 150,000 lines twice.
- Fix: drop the grep line of bench-budget, since make metrics records and compares the figure, and update its help text, the map, and the Makefile's stage notes.
### A records run's advisories located in docs/backlog.md open fix rounds the contributor cannot act on
- Location: the advisory fix rounds of `.claude/workflows/deliver-change.js` on a `sprint-N-records` change; near the backlog queue's Pool item `rework-review-repeat` (an advisory-only round counts as rework).
- Why: sprint-21-records rework 2 of 3 from two advisory-only rounds plus one close-advisories start, 2 of those 3 starts made no commit, advisories_closed 0 left 4, all four in docs/backlog.md, which a delivery never reads; sprint-17 to -20-records rework 2, 2, 1, 1 against 0 for sprint-15 and -16 (sprint-21-records retro note 8).
- Fix: record such an advisory once in docs/findings/ and open no fix round for it; accepted when such a records run reaches packaging with rework 0 and no contributor start that ends with no commit.

### A repeated advisory of a records-only fix round is recorded twice
- Location: the package step's advisory recording in `.claude/workflows/deliver-change.js`, the advisories_left count of the run state.
- Why: sprint-21-records notes 5 and 6 at 934b93604302 repeat notes 3 and 4 at 528d21f2c165, so advisories_left is 4 for 2 distinct findings and docs/findings/ counts one defect twice; the quality review 2557/5 and the closing start 991/1 were spent on the repeats (sprint-21-records retro note 9).
- Fix: match a later round's advisory to an earlier one by location and finding before recording; accepted when a records-only fix round's repeats are not re-recorded and advisories_left equals the distinct findings.

## Findings of grep-long-files after its package step

- quality advisory docs/findings/grep-long-files.md:10 docs format: the planner's appended entry '### A records run's advisories...' follows the previous entry's Fix line with no blank line, because plan-apply appends build/plan/ change /backlog.md with a bare cat (tools/run_state.sh:1926); fix: insert the blank line, and have plan_apply print a separating newline before appending to a non-empty fin
