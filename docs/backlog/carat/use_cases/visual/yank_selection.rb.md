# Backlog: carat/use_cases/visual/yank_selection.rb

### Untested behavior (sprint-20 sweep quality, yank_selection.rb:28)

- Location: `carat/use_cases/visual/yank_selection.rb:28`
- Why: untested behavior: the E354 refusal of a visual yank into a read-only register, and of a visual change (change_selection.rb:32), has no test (test/editor_registers.rb:136-140 cover normal yank, visual delete, and normal change), nor has the Not implemented outcome of a visual.* key outside a visual mode (selection_handler.rb:96)
- Fix: add table rows to test/editor_visual.rb or test/editor_registers.rb
- Also: test/editor_registers.rb, test/editor_visual.rb
- Category: editor
- Added: 2026-11-19
