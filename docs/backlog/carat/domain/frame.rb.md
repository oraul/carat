# Backlog: carat/domain/frame.rb

### Frame, status bar, and screen presenter repeats

- Location: carat/domain/frame.rb:36, carat/adapters/status_bar.rb:1 and :47, carat/adapters/screen_presenter.rb:193 (sprint-4 sweep, quality).
- Why: Frame::REPLACEMENT repeats Utf8::REPLACEMENT; an unused plugin_api require; NO_NAME defined in four files (also tab_bar.rb:22, winbar.rb:18, list_buffers.rb:20); two loops inline same_cell?.
- Fix: one constant each, drop the require, call same_cell? unless a bench shows a cost.
- Also: carat/adapters/status_bar.rb, carat/adapters/screen_presenter.rb
- Category: editor
- Added: 2026-11-14

### Names and menus still draw format code points raw
- Location: `carat/domain/frame.rb` `put_from` (:195) and `DisplayWidth.text_width`, `bytes_within`, used by the tab bar, the status bar, floats, menus, and markdown text
- Why: a buffer name, a symbol name, or a float line holding U+202E or U+200B is still stored in a cell as it is, so a terminal reorders or hides the row; only buffer-line text goes through `LinePainter` here
- Fix: have `put_from` store U+FFFD (or the marker) for `format_char?` beside `control?`, and count the same in `text_width`, `bytes_within`, and `markdown_text`, with a frame test per writer
- Category: editor
- Added: 2026-11-24

### Frame#put_from writes bidirectional and zero-width format code points raw (security Low (6))

- Where: `carat/domain/frame.rb:195`.
- Why it matters: `DisplayWidth.of` gives them width 1, so they are not skipped; a buffer name, a file name in the tab or status bar, or LSP hover and float text holding U+202E can make the terminal reorder or hide the row, a visual spoofing of what the user sees outside buffer lines.
- Fix outline: in `put_from`, map `DisplayWidth.format_char?(raw)` to `REPLACEMENT` (or the `<xxxx>` marker) beside `control?`, and count the same in `text_width`, `bytes_within`, and `markdown_text`, with a frame test for each writer.
- Category: security
- Added: 2026-11-24
