# Backlog: test/runner/run_all.rb

## Two style slips of 31919d9

- Where: `test/runner/run_all.rb` line 81 and its dispatch at line 178 (`editor_breadcrumbs` out of alphabetical order); `carat.rb` line 4 (a 90-character header line), at 31919d9. Periodic quality. Queue item: backlog items, the runner's test order and comments off their wrap; fold the second into Nine comments break their file's wrap width.
- Why it matters: every other test keeps alphabetical order; the header breaks its wrap width.
- Fix outline: move both lines to their place; rewrap lines 2 to 6.
- Also: carat.rb
- Category: code-quality
- Added: 2026-11-09
