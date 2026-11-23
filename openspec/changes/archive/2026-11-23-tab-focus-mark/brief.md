# Brief

tab-focus-mark: the third Sprint 31 feature item in docs/queue-feature.md at 38642f0, after one-accent-tabs (#325), by the user's request after the tabs council (tmp/briefs/tabs-council.md); run it exactly as its queue entry says, quoted below. Touch no file of the backlog lane (docs/queue-backlog.md, docs/metrics-backlog.tsv). No model name or alias anywhere in names or prose. If the change edits tools/rules.sh, stop and name it.

The queue entry: `tab-focus-mark` (T2 user request, estimated small): Where: `carat/adapters/tab_bar.rb:53`, `:92`. Why: with the explorer focused no tab is marked. Fix outline: the file window's tab stays marked while a sidebar has focus. Accepted when a test focusing the explorer shows the file's tab selected, failing before.
