### A records change sends quality advisories to fix rounds it cannot close (sprint-23-records retro note 9)
- Location: `.claude/workflows/deliver-change.js`, the records lane's quality and closing phases; joins the queued closing-loop-fold.
- Why: sprint-23-records ran 2 rework rounds and 1 closing start and closed 0 of 7 advisories, the quality phase 12270 of 63840 output tokens (19.2 percent); sprint-21-records rework 2 with 4 left, sprint-20-records 3 left.
- Fix: route a records change's advisories on groom output to its findings file without a fix round; accepted when the next three records runs show rework 0 from advisory-only rounds, no closing start, and quality under 8 percent of output, every advisory still recorded.

### The benchmark runs on records changes with no carat file (sprint-23-records retro note 10)
- Location: `.claude/workflows/deliver-change.js`, the bench phase; complements the queued records-bench-skip.
- Why: 5144 of 63840 output tokens (8.1 percent) and 9 of 114 calls, allocations and rounds unchanged; sprint-22-records 5455/10 (11.6 percent), sprint-20-records 4548/5 (9.3 percent).
- Fix: a records change with 0 files under `carat/` records the bench as carried with 0 calls and its pull request Testing line says so.

### groom folds the none/None lines of findings files (sprint-23-records retro note 11)
- Location: `tools/run_state.sh` groom's findings fold; `docs/backlog.md:922`, `:9956`, `:9962`; merge into the entry sprint-23-records recorded for its notes 1 and 4.
- Why: 3 stray lines raised 2 of the run's 7 advisories and one of its 2 rework rounds.
- Fix: accepted when a tools-test folds a findings file holding only none/None, or ending in such a line, without that line, and the next records run raises no placeholder advisory.
