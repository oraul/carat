# Backlog: carat/domain/folds.rb

### The closed fold's text is not the design's chevron and count
- Location: carat/domain/folds.rb:316 to :326 (`label`, Neovim's `+--N lines: text` filled with FILL), against docs/design.md:75 and :76 (a faint `▸` for a fold's closed gap, a dim `⋯ 12 lines` count).
- Why: folded-row paints the row in its own dim group, `Folded`, as the brief asks, but the text still differs from the binding look, and docs/design.md section 7 lists no Known drift row for it.
- Fix: decide the fold text (keep Neovim's default or draw `▸ first line ⋯ N lines`), then change `Folds#label` and its scenarios in openspec/specs/folds/spec.md and the whitespace-marks test; or add the gap to the Known drift table with its closing item.
- Also: docs/design.md, openspec/specs/folds/spec.md
- Category: editor
- Added: 2026-11-22

### The fold label's fill is not ASCII under option.icons ascii and NO_COLOR
- Location: carat/domain/folds.rb:21 (`FILL = "·"`), used by `label` at :316; the frame presenter's ascii switch at carat/adapters/frame_presenter.rb:244 does not reach it.
- Why: an ascii frame elsewhere holds no byte above 127 (test/adapters_frame_presenter.rb, the ascii frame check), but a closed fold's row still draws U+00B7 there, and under NO_COLOR, which asks for ASCII glyphs.
- Fix: pass the ascii flag to the label (or a fill string) and fill with `-` as Neovim's `fillchars` fold default does; a test drawing a closed fold under `option.icons ascii` asserting no byte above 127.
- Also: carat/adapters/frame_presenter.rb, test/adapters_frame_presenter.rb
- Category: editor
- Added: 2026-11-22
