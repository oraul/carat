# Backlog: carat/domain/decoded_line.rb

## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers

- Where: `DecodedLine.decode` and `FramePresenter#paint_text` (`carat/domain/decoded_line.rb`, `carat/adapters/frame_presenter.rb`); `utf8-input-safety` draws each byte outside a well-formed UTF-8 sequence as one U+FFFD cell.
- Why it matters: Neovim shows such a byte as a four-cell `<xx>` marker, so two lines that differ only in an illegal byte look alike here, and the byte cannot be read from the screen.
- Fix outline: decode an illegal byte to a code that keeps the byte (for example a private marker range), draw it as `<xx>` the way the C1 markers are drawn, measure it as four cells in `DecodedLine`, `DisplayWidth`, and the cursor placement, and add rows to `test/domain_utf8.rb` and `test/adapters_frame_presenter.rb`.
- Also: carat/adapters/frame_presenter.rb, test/domain_utf8.rb, test/adapters_frame_presenter.rb
- Category: editor
- Added: 2026-11-03

### Four display methods are dead code
- Location: carat/domain/decoded_line.rb:91 (cells); carat/adapters/painted_rows.rb:107 (syntax_at); carat/domain/frame.rb:129 (clear); carat/plugins/explorer/tree.rb:38 (marked)
- Why: nothing calls them. Folded into ui-code-tidy.
- Fix: remove them.
- Also: carat/adapters/painted_rows.rb, carat/domain/frame.rb, carat/plugins/explorer/tree.rb
- Category: editor
- Added: 2026-11-17

### DecodedLine and Cell are immutable Structs

- Location: carat/domain/decoded_line.rb:15, carat/domain/cell.rb:8 (sweep, quality).
- Why: documented as never changed after built, yet Structs, while CLAUDE.md makes immutable values Data subclasses.
- Fix outline: make them Data, or record why the hot path needs a Struct.
- Also: carat/domain/cell.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-17
