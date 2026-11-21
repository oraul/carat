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

### The MODIFIED scenario title still says gem
- Location: openspec/changes/tabs-only-dot/specs/buffer-tabs/spec.md:14, test/adapters_tab_bar.rb:125, tasks.md 1.1
- Why: the scenario "The ascii icons give the ascii gem and separator" asserts no gem; a MODIFIED block must keep its title to match the main spec.
- Fix: a later change renames it to "The ascii icons give the ascii separator and no gem" in the main spec, the test label, and its tasks.
- Category: code-quality
- Added: 2026-11-21

### Buffer-tabs scenario title still says gem after the gem was removed
- Location: the buffer-tabs spec scenario 'The ascii icons give the ascii gem and separator', test/adapters_tab_bar.rb:125 comment, the archived tabs-only-dot tasks.md 1.1
- Why: the scenario now asserts no gem, but a MODIFIED block must keep the title, so the name no longer fits.
- Fix: a later change renames it 'The ascii icons give the ascii separator and no gem' in the spec (as a RENAMED requirement), the test comment, and the task.
- Category: code-quality
- Added: 2026-11-21
