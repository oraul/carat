# Backlog: test/plugins_explorer.rb

## Explorer test helpers and icon tables

- Where: `tree_over` in `test/plugins_explorer.rb` line 64 (unused parameter; an assignment inside an argument at 127; a ternary assert at 85); `Icons.table` and `NAMES` in `carat/domain/icons.rb` lines 132 and 13; DisplayWidth rows in `test/domain_icons.rb` lines 78 to 92, at 5e4c140. Periodic quality. Queue item 38.
- Why it matters: a key added to a table without `NAMES` goes untested; tests of one module sit in another's file.
- Fix outline: drop the parameter and split the statements; make `table` private and derive names from the tables; move the rows to `test/domain_display_width.rb`.
- Also: carat/domain/icons.rb, test/domain_icons.rb, test/domain_display_width.rb
- Category: plugins
- Added: 2026-11-09
