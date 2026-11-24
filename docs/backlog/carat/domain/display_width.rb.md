# Backlog: carat/domain/display_width.rb

## Bidi and zero-width format characters reach the terminal raw

- Where: `carat/domain/display_width.rb` line 66 (`control?` and `code_cells`), at 31919d9; reached from buffer text, server text, and names through `carat/adapters/frame_presenter.rb`. Periodic security Medium (5). Queue item `bidi-controls`.
- Why it matters: U+200B to U+200F, U+202A to U+202E, U+2060 to U+2069, U+FEFF, and U+061C count as one cell and are written raw, so a hostile file can reorder the shown code on a bidi-rendering terminal (Trojan Source) or desync columns.
- Fix outline: treat them as controls, shown as a visible placeholder in buffer text and dropped from control-stripped text, with `test/domain_utf8.rb` and `test/editor_screen.rb` rows per source.
- Also: carat/adapters/frame_presenter.rb, test/domain_utf8.rb, test/editor_screen.rb
- Category: security
- Added: 2026-11-09

## DisplayWidth.bytes_within is public for one caller

- Where: `DisplayWidth.bytes_within` in `carat/domain/display_width.rb` line 148, called only by `cut` and a test, at 6141633. Quality advisory of `palette-pad-crash`. Queue item: backlog items, needless public methods.
- Why it matters: needless public surface, the same kind as the entry Seven more methods are public with no outside caller.
- Fix outline: move the stray-byte rows of its test to `cut` and make `bytes_within` private to `DisplayWidth`.
- Category: editor
- Added: 2026-11-09

### Dead display helpers

- Location: carat/domain/display_width.rb:37, carat/adapters/frame_presenter.rb:316 and :321, carat/domain/frame.rb:62 (sprint-4 sweep, quality).
- Why: DisplayWidth.of_char has no caller; display_col and display_width serve one test; Frame#index serves one test while every method inlines it; the map lists them.
- Fix: delete them, move the tests to DisplayWidth.column, update the map (code_cells in of_char's place).
- Also: carat/adapters/frame_presenter.rb, carat/domain/frame.rb
- Category: editor
- Added: 2026-11-14

### Soft hyphen and other invisible code points stay raw
- Location: `carat/domain/display_width.rb` `format_char?`
- Why: U+00AD, U+180E, and U+034F take no cell or an uncertain one in some terminals; the set follows Vim's plus the finder's, so they are not marked
- Fix: add them to `format_char?` after checking how Neovim draws each, with a row in the width table
- Category: editor
- Added: 2026-11-24

### Two tables of the format code points drift apart at carat/domain/display_width.rb:190 (sprint-32 review quality)
- Location: carat/domain/display_width.rb:190 (format_char?, render-text-lows), carat/plugins/finder/safe_text.rb:71 (format_control?)
- Why: the editor marks U+2060 to U+206F while the finder blanks only U+2066 to U+2069, and nothing keeps the two lists in step, so a word joiner or invisible operator is marked in file text but passes raw through the finder's rows.
- Fix: one table offered to plugins through the plugin API that both read, with a test row per range.
- Category: quality
