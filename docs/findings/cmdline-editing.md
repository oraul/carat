### A direct write of the command line text keeps the old cursor count
- Location: carat/domain/editor_state.rb (`cmdline_after`, `replace_cmdline`)
- Why: the cursor is the count of characters after it, so a text assigned with `state.cmdline =` after a cursor move keeps that count and the cursor lands inside the new text; every shipped writer uses `replace_cmdline`, but nothing forbids a later one
- Fix: have test/lint.rb refuse `.cmdline =` outside `carat/domain/editor_state.rb`, or make the writer reset the count
### A plan's queue cut that greens a red main docs-lint waits for the package step

- Location: `tools/docs_lint.sh:208` (QUEUE_BUDGET 17,969, both lanes together) and the package step's `plan-apply`; showtabline note 4, backlog-per-file note 2.
- Why: showtabline's check at a3a1729 failed docs-lint on main's queue (18,297 of 17,969 bytes at 7f96588) though its plan cut the queue, first.check=0, rework 1 of 3, check 142,908 of 452,689 output (31.6 percent); backlog-per-file paid a fix round for the same base overrun (branch 18,295 bytes), check 36,159 output over three passes.
- Fix: a change that does not grow the lane queues passes while its base is over budget, and the commit pushing them over is the one refused; accepted when a plan that records a Red main docs-lint decision passes docs-lint at its first check without a fix round.

### plan-apply copies a plan older than the branch's queue

- Location: the package step's `plan-apply` in `tools/run_state.sh`; backlog-per-file note 3.
- Why: second occurrence: #263 lost 5 items; #278's plan predated #276 and branch commits ec40276, 9f981a9, re-adding merged backlog-records-rule and dropping 3 Decisions lines; the contributor restored it by hand, package 62,305 output on 20 calls (11.3 percent of 551,639).
- Fix: leave untouched, or refuse, a queue whose plan predates the queue's last commit; accepted when packaging needs no manual restore over the next three deliveries.

### The contributor's self-check says match while a fast stage fails

- Location: the contributor's implement result (`self_check`) in `.claude/agents/contributor.md` and `.claude/workflows/deliver-change.js`; showtabline notes 1, 2, 5, backlog-per-file notes 1, 4.
- Why: showtabline reported match with docs-lint failing and missed a second FAIL (docs/architecture.md 36 bytes over budget), escalating to the session tier; backlog-per-file said match while quoting docs-lint failing; 14 self-check-mismatch notes across 9 run states; check first pass 222/234.
- Fix: either return match only when every fast-stage FAIL line is gone or named, or drop the verdict that never changes the route; accepted when self-check-mismatch notes drop to 0 over the next 5 runs and check first pass stays at or above 221/233.

### Pull request text claim check blocks a first pass (showtabline evidence for the package step's over-claim entry)

- Location: `tools/open_pr.sh` gate and the contributor's package mode; showtabline notes 6, 7; near-same as "### The package step's pull request text over-claims its own bookkeeping commits", to be merged into it.
- Why: showtabline pr-text-blocked round 1 (a table-driven claim true for 1 of 4 test files), prtext 4,347 output on 13 calls, pushes 2; pr_text_fixes in 6 of the 13 newest runs.
- Fix: as that entry; accepted when pr-text-blocked appears in at most 1 of the next 6 runs.

### Medium-estimate feature runs overrun their 1.2M budget

- Location: `docs/goals.md` The rubric (sizes) and `sh tools/run_state.sh budget`; showtabline note 3, backlog-per-file note 5.
- Why: showtabline 1,365,817 total tokens, 247,686 output against the medium output budget 200,000; backlog-records-rule 1,433,807 in 75 minutes; feature mediums in the last 10 rows 1,226,138 to 2,192,549, 5 of 5 over 1.2M.
- Fix: recalibrate the medium budget from the lane histories or estimate such features large; accepted when at most 1 of the next 5 medium runs overruns.
