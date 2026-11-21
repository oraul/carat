# Backlog: test/adapters_tab_bar.rb

## The tab-bar test's unlisted fixture reads ambiguously

- Where: `test/adapters_tab_bar.rb:31` and `:65`. Quality advisory of `jump-replace-tab`.
- Why it matters: the setup strips `*` then `~` but tests both flags with `start_with?` on the raw name, so `~*a.txt` or `*~a.txt` would build a buffer other than the one written; the `unlisted` comment reads as if three paths were listed twice.
- Fix outline: read each prefix once into a flag, or document the one allowed order; reword the comment to "The paths f0.txt to f9.txt with f0.txt, f3.txt, and f9.txt left unlisted by a jump: seven tabs." Backlog batches (test hygiene).
- Category: code-quality
- Added: 2026-11-10

### Quality: the modified-mark width table does not prove the change, test/adapters_tab_bar.rb:105

- Why: the table passes unchanged on main's code because every shipped mark is already one cell, it compares `String#index` character offsets rather than cell columns, and its labels nerd, unicode, and ascii do not name the scenario in the snapshot.
- Fix: label the rows `<set>: the modified mark keeps the tab's width` and compare the cell column of b.txt's first cell.
- Category: code-quality
- Added: 2026-11-14
