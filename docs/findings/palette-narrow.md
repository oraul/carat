### The contributor's self-check and the quality reviewer use different blocking checklists (lsp-container-b retro note 11)
- Location: `.claude/agents/contributor.md` self-check, `.claude/agents/quality-reviewer.md` blocking rules
- Why: quality failed its first pass in lsp-container-b (SIGPIPE ending carat on stop), quality:0 in 5 of the last 11 feature rows and 66 of 130 over all changes against check 128/130 and security 125/130; the fix round cost implement 153,294 of 264,142 output (58.0%) and took the run over its 200,000 output budget (229,659). Adds evidence to "### Quality fails its first pass on about half the runs".
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median.

### A post-review prose edit in the package step refuses the push (lsp-container-b retro note 12)
- Location: the package step of `.claude/workflows/deliver-change.js`, the review-currency check of `tools/run_state.sh push`
- Why: a docs-only wording fix of `docs/architecture.md:275` invalidated the recorded check and security review, 1 refused push, the edit reverted and the stale Open3 sentence left on main; package 21 of 210 tool calls (10.0%).
- Fix: settle the advisories the package step may fix before the last review, or exempt pure prose edits from invalidating it; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit.

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: the last ten backlog rows ran 3.5 to 59 total per output; sprint-12-records 36,282 output projected 217,692 against 2,147,268 actual (over small 500,000 by 4.3x), windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 over 1,200,000 at 4.8 and 10.7, sprint-security's line said under at 131,132 output. Folds into `budget-prediction`.
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its size budget.

### The scout's pack is redone by the contributor (sprint-security retro note 7)
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: sprint-security scout 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them; backlog rows scout share 18.4% to 40.1% over five runs. Folds into `scout-value`.
- Fix: accepted when, over the next five runs that start a scout, scout output stays under 10% of the run's output with no drop in the quality first-pass rate.

### The quality reviewer reports advisory classes the package step always drops (sprint-security retro note 9)
- Location: `.claude/agents/quality-reviewer.md` advisory rules, the package step's advisory triage
- Why: 3 of sprint-security's 6 advisories (naming, repeated prompts, a duplicated format) were dropped as changing no decision; reviews 15,732 output and 28 of 126 calls (22.2%).
- Fix: accepted when over the next five runs the package step drops no advisory class the reviewer reported, the reviewer no longer reporting that class, with first-pass blocking findings unchanged.
