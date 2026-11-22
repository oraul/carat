### Space f w takes no word to the right of a blank cursor
- Location: carat/plugins/finder/plugin.rb `word_under_cursor`, carat/plugins/finder/matcher.rb `word_at`.
- Why: Neovim's cword takes the next word to the right on the line when the cursor is on a blank; the queue entry asks for the empty grep on a blank, so this change opens it empty, which differs from Neovim for a user who expects the nearest word.
- Fix: when word_at finds no word at the column, scan right on the same line for the first keyword byte and return its run; add a table row and a spec scenario, and change the compatibility row.

### word_at counts every non-ASCII character as a word character
- Location: carat/plugins/finder/matcher.rb `word_byte?` (bytes of 0x80 or more), used by `word_at`.
- Why: a typographic quote, a non-breaking space, or CJK punctuation next to a word joins it, so Space f w can put the punctuation on the prompt; the grep picker's whole-word match shares the rule, so changing one alone would make them disagree.
- Fix: classify code points by Unicode letter and number classes through a table in Matcher for both word_at and the whole-word match, with rows for each class.

### docs/architecture.md stood over its docs-lint budget on main
- Location: docs/architecture.md, the configuration section's trust bullet and the line-check bullet; tools/docs_lint.sh BUDGETS.
- Why: the merge of the project-file trust fix left the file 8 bytes over its 88064-byte budget, so make docs-lint, a stage of the check, failed for every later change; this change trimmed 9 bytes of wording to get under it.
- Fix: keep the file under budget by trimming wording at the change that grows it, and have the merge gate run docs-lint on the pull request's head so a budget overrun fails before the merge.
### A first-pass green CI still costs the merge start 13 to 14 calls (picker-speed retro note 2)
- Location: .claude/workflows/deliver-change.js, the merge phase and the merger start; beside the backlog queue's `merge-wait-bound` (merge 78,615/13, drivers-lsp-lows retro 6).
- Why: picker-speed merge 22,874 output tokens in 14 calls, 15.4 percent of 148,771 output tokens, with a first-pass green CI; the fixed merge cost repeats every run.
- Fix: fold into `merge-wait-bound`; accepted when over the next 5 runs with first.ci=1 the merge phase takes at most 8 tool calls and at most 10 percent of the run's output tokens, the merged commit still accepted by the run state.

### A scout runs when the plan already names every expected path with a line (picker-speed retro note 3)
- Location: .claude/workflows/deliver-change.js, the scout phase; beside the backlog queue's `scout-prune` and `areas-in-plan`.
- Why: picker-speed scout 14,768 output tokens in 11 calls, 9.9 percent of output tokens and 9.6 percent of calls, while the plan named every path with a line and the pack changed no decision.
- Fix: fold into `scout-prune`; accepted when a run whose plan names every expected path with a line starts no scout and the check first-pass rate stays at or above 242/256.

### The benchmark cannot see growth in the float, finder, or palette allocations (picker-speed retro note 4)
- Location: tools/metrics.sh (the allocs column), bench/run.sh `PICKER_BUDGETS`.
- Why: tools/metrics.sh records no lh-float, finder, or palette allocations, so make metrics-compare cannot fail on their growth; PICKER_BUDGETS allows about 60 percent growth under its fixed maxima.
- Fix: record lh-float, finder, and palette in the allocs column; accepted when the next metrics row holds them and a growth of one object a key in any of them fails make metrics-compare.

### The check phase overran the large output budget (review-in-openspec overrun note 8)
- Location: .claude/workflows/deliver-change.js, the check phase; beside the backlog queue's `check-carry` (check 121,585 of 724,443 output, review-in-openspec retro 9).
- Why: the check passed at 8045d5552c96 with 653,549 output tokens against the large output budget of 416,666.
- Fix: fold into `check-carry` as its evidence; accepted as that item says (the check under 8 percent of output tokens over three first.check 1 deliveries).

### The contributor overran the medium budget at agent/high (review-in-openspec overrun note 12)
- Location: docs/goals.md Calibration, the contributor-tier-high end; .claude/workflows/deliver-change.js CALIBRATION.
- Why: estimated medium, budget 1,200,000 total tokens, actual 1,372,173 total tokens in 76.0 minutes, 260,867 output tokens.
- Fix: count it in the contributor-tier-high comparison; accepted when the next calibration decision cites this row with its figures.

### sprint-27-records ran 44.3 minutes against the small budget of 25 (sprint-close-lows overrun note 4)
- Location: docs/goals.md budgets, the records change; beside the backlog queue's `budget-recalibrate` (sprint-26-records budget 0 against 2,612,300).
- Why: estimated small, budget 500,000 total tokens and 25 minutes, actual 0 total tokens in 44.3 minutes, 32,707 output tokens, 8,122,940 total tokens of sprint-planning's reviews set apart.
- Fix: fold into `budget-recalibrate`; accepted when a records change's budget counts its reviews' tokens and minutes or names them apart, and the next records row is judged against it.
