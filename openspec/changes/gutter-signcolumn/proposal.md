## Why

A buffer with signs gives its sign column two cells, the glyph in the first and a blank after it, so every sign costs a cell of text width that shows nothing. The Facet plan the user accepted draws the sign column one cell wide, always: every sign glyph of the icon sets is one cell, so the second cell is only padding.

## What Changes

- The sign column of a buffer with signs is one cell wide: the sign's glyph in its kind's group, or a blank in `SignColumn`, then the line numbers or the text at once, so the numbers and the text sit one cell further left than before and the cursor with them.
- A buffer with no signs still has no sign column; a scratch buffer with signs still shows its one-cell column without numbers.
- Roadmap: no new roadmap item; the Facet wave 2 user request on the sign column (section 12), after `sign-colors`.
- Out of scope: an `option.signcolumn` setting, choosing the most severe of two owners' signs on one row (the first registered owner still shows), new sign kinds, and the number column's width.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the sign column is one cell wide.

## Impact

- Domain: `Window::SIGN_WIDTH` is 1, so `Window#gutter_width` counts one cell for signs.
- Adapters: `FramePresenter#paint_row` fills one `SignColumn` cell and cuts a glyph to one character; `number_shown` follows the constant.
- Use cases: none changed; `ArrangeView`, `ShowCompletionDocs`, and `SplitWindow` read `gutter_width`, so the cursor and the width a split needs follow.
- Tests: `test/adapters_frame_presenter.rb` (the sign column rows, the sign colors rows, the scratch window's sign) and any frame row of another test that shows a sign.
- Docs: `docs/compatibility.md` (the sign column is one cell, where Neovim draws two) and `docs/architecture.md` (the `FramePresenter` entry), `docs/codebase-map.md` unchanged (no file added, moved, or removed).
- README.md: unchanged, it does not describe the sign column's width.
- docs/architecture.md: changed, its `FramePresenter` entry says the sign column is one cell.
- Assumptions: every glyph the icon sets give a sign is one cell wide, as the `DisplayWidth` table measures it (the Nerd Font private use glyphs included), so cutting a glyph to its first character loses nothing; a plugin's own glyph longer than one character shows its first.
