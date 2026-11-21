# Backlog: carat/domain/selection_cut.rb

## A block's top-left column is computed in six places

- Where: `carat/domain/selection_cut.rb` line 25 and `carat/use_cases/visual/` `yank_selection.rb` line 32, `shift_selection.rb` line 17, `change_selection.rb` line 44, `put_over_selection.rb` line 39, `insert_at_selection.rb` line 40 at 9a92265. Periodic quality. Queue item: backlog items, copies.
- Why it matters: architecture section 5 moves logic several use cases share into the domain.
- Fix outline: one `Block` method beside `reaching_rows`, called from the six places.
- Category: editor
- Added: 2026-11-09

### Duplication (sprint-20 sweep quality, selection_cut.rb:30)

- Location: `carat/domain/selection_cut.rb:30`
- Why: duplication: the block's top-left column, block.span(buffer.line(block.top), tabstop).from followed by a clamped move, is computed again in yank_selection.rb:39, shift_selection.rb:22, change_selection.rb:53, and put_over_selection.rb:39
- Fix: one Block method (e.g. left_col(buffer, tabstop)) used by all five
- Category: editor
- Added: 2026-11-19
