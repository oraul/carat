# Backlog: docs/queue-feature.md

### Queue entries keep stale line references after their change edits the named code

- Location: docs/queue-feature.md:7 (the `ruby-structure-remove` entry), test/lint.rb (the named-path check)
- Why: the delivery had to unquote the two paths it removes so lint's path check passes, leaving the entry's line references (plugin.rb:86 and :111, tokenizer.rb:820, test/plugins_ruby.rb:145) pointing at code that no longer exists, and a delivery editing its own planner-written queue entry bypasses plan-apply.
- Fix: leave queue entries to plan-apply and have the lint path check skip docs/queue-*.md entries whose change is the branch's own, or drop the stale line numbers from queue entries.
- Also: test/lint.rb, test/plugins_ruby.rb
- Category: pipeline
- Added: 2026-11-17

### The Sprint 17 feature decision still places tab-close-d at place 1
- Location: `docs/queue-feature.md:30`.
- Why: the merge resolution of tab-close-d removed it from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list holds vim-folds-b at 1 and vim-line-commands-c at 2 (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2.
- Category: pipeline
- Added: 2026-11-18

## Findings of tab-close-d after its package step

- quality advisory docs/queue-feature.md:30 docs currency: the merge resolution removed tab-close-d from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list now has vim-folds-b at 1 and vim-line-commands-c at 2; fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2
- quality advisory docs/findings/tab-close-d.md:11 one clear way: the three new entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use; fix: backtick the locations and end each Location, Why, and Fix line with a period as above
- Category: pipeline
- Added: 2026-11-18
