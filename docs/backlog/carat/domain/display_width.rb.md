# Backlog: carat/domain/display_width.rb

## code_of decodes UTF-8 inside DisplayWidth

- Where: `DisplayWidth.code_of` in `carat/domain/display_width.rb` (line 54), a decoding helper in the width table. Advisory of the periodic quality review at 6ea61b1; `feedback` deleted its only `Motions` caller, the dead `Motions.keyword?` and `char_class`, with the `display_width` require.
- Why it matters: a decoding helper kept in the width table hides the dependency and invites another copy.
- Fix outline: move it to `Utf8` (for example `Utf8.first_code`) and call it from `DisplayWidth`.
- Category: editor
- Added: 2026-11-03

## DisplayWidth.of_char has no caller

- Where: `DisplayWidth.of_char` in `carat/domain/display_width.rb` (line 37 at `start-screen`), called nowhere in `carat/`, `bin/`, `test/`, or `bench/`, yet named as a key method on the map's `display_width.rb` line. Periodic quality at 5ac9674.
- Why it matters: the map points readers at a method nothing uses, and it can drift from the width rule the callers rely on.
- Fix outline: delete it and drop it from the map's line.
- Category: editor
- Added: 2026-11-05

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

### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))

- Location: `carat/domain/display_width.rb:12`
- Why: Unicode format characters (bidi overrides U+202A-U+202E, isolates U+2066-U+2069, zero-width U+200B-U+200F, U+FEFF) in file text are painted raw as one-cell glyphs by FramePresenter#paint_text (carat/adapters/frame_presenter.rb:1103), so a crafted file can display differently from its content (Trojan Source) and shift columns
- Fix: treat general category Cf as control in DisplayWidth.control?/code_cells and paint it as <u+xxxx> like the C1 controls, as Finder::Grep#safe already does for the picker
- Also: carat/adapters/frame_presenter.rb
- Category: security
- Added: 2026-11-20
