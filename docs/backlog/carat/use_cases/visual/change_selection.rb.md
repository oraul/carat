# Backlog: carat/use_cases/visual/change_selection.rb

## The linewise change and its cursor are written in four places

- Where: `carat/use_cases/visual/change_selection.rb:40`, `delete_lines.rb:24`, `selection_cut.rb:22`, and `carat/use_cases/operate.rb:143` and 157. Periodic quality at ce6abdb, the part of its editing-copies finding no other entry names; queue item `editing-counts`.
- Why it matters: one rule spelled in four places drifts.
- Fix outline: `Operators` helpers for the linewise change and its cursor, called by all four.
- Also: carat/use_cases/operate.rb
- Category: editor
- Added: 2026-11-10

### Change selection repeats Operate's linewise change (sprint-16 sweep quality)

- Location: carat/use_cases/visual/change_selection.rb:43, carat/use_cases/operate.rb:189.
- Why: the autoindent, set_lines, cursor, and insert-mode steps of a linewise change are copied.
- Fix outline: one domain function returning the indent column, called by both.
- Also: carat/use_cases/operate.rb
- Category: editor
- Added: 2026-11-18

### duplication: the linewise change branch (register, autoindent indent, set_lines, insert at carat/use_cases/visual/change_selection.rb:40 (sprint-32 sweep quality, note 27)
- Location: carat/use_cases/visual/change_selection.rb:40
- Why: duplication: the linewise change branch (register, autoindent indent, set_lines, insert mode, cursor) repeats Operate#change's linewise branch (carat/use_cases/operate.rb:195)
- Fix: move the linewise change into one shared domain function both call
- Category: quality
