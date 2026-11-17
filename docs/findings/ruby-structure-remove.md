### Queue entries keep stale line references after their change edits the named code

- Location: docs/queue-feature.md:7 (the `ruby-structure-remove` entry), test/lint.rb (the named-path check)
- Why: the delivery had to unquote the two paths it removes so lint's path check passes, leaving the entry's line references (plugin.rb:86 and :111, tokenizer.rb:820, test/plugins_ruby.rb:145) pointing at code that no longer exists, and a delivery editing its own planner-written queue entry bypasses plan-apply.
- Fix: leave queue entries to plan-apply and have the lint path check skip docs/queue-*.md entries whose change is the branch's own, or drop the stale line numbers from queue entries.
### The mid-run output-token overrun check flags runs their totals do not confirm
- Location: `.claude/workflows/deliver-change.js`, the overrun check at the check pass (output tokens times 6 against the size's total budget)
- Why: tab-close-c flagged 219,748 output tokens against 200,000 while its total, 830,180, stayed under 1,200,000; the last 10 feature rows have total-to-output ratios 2.2 to 7.9, not 6, and 6 of them passed 200,000 output tokens while only markdown-reading-c (1,902,958) passed the total budget.
- Fix: base the mid-run flag on recorded totals or a ratio taken from the lane history; accepted when, replayed over the last 10 feature rows, it flags only rows whose total_tokens exceeded their size budget.

### The merge phase's output tokens vary 14-fold on a first-pass green CI
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: its only decision on a green CI is to merge, yet tab-close-c spent 52,904 output tokens in 11 calls (17.6% of 300,034), against vim-line-commands-a 4,992 and tab-close 5,808 at 11 calls; palette-narrow 69,031.
- Fix: accepted when over the next 5 runs with first.ci=1 the merge phase stays under 10,000 output tokens.

### Records changes are judged against the small budget with the sprint reviews in their totals
- Location: the budget line of `sh tools/run_state.sh budget`, the estimate of a `sprint-N-records` change
- Why: sprint-12-records 2,147,268, sprint-13-records 1,264,361, and sprint-14-records 1,973,945 total tokens against 500,000 (3 of 3 over) with only 36,282, 42,893, and 32,743 output tokens; sprint-14-records weighted phases periodicreview 19,054,636 and review 3,756,759 against deliverchange 3,040,840; the same proposal is ci-trust-gaps retro note 6.
- Fix: accepted when the next records row's budget line compares only its delivery phases with its size, or budgets the sprint review in its own line, and does not start with over for that reason alone.
