# Backlog: carat/use_cases/ex/line_command_handler.rb

### place_cursor clamps by the mode's max_col, not as in normal mode
- Location: carat/use_cases/ex/line_command_handler.rb:57
- Why: place_cursor now clamps through EditorState#max_col, which allows the column past the last character in insert and visual modes, where the old code always clamped as in normal mode (a line command run by a plugin's run_ex in insert mode or a : binding in visual mode); the new comment's '(the end of the line for a wanted column past it, -1)' is garbled.
- Fix: keep the normal-mode clamp or state the mode dependence and reword the comment.
- Category: editor
- Added: 2026-11-18

### place_cursor's clamp now depends on the mode, without a test
- Location: carat/use_cases/ex/line_command_handler.rb:496
- Why: place_cursor now clamps through EditorState#max_col, which lets the column sit past the end in insert and visual modes, where the old code always clamped as normal mode does (a line command a plugin runs outside normal mode); no test covers the mode dependence.
- Fix: keep the normal-mode clamp (length - 1), or state the mode dependence and test it.
- Category: editor
- Added: 2026-11-18
