## Context

`Window::SIGN_WIDTH` is 2 (`carat/domain/window.rb:27`); `Window#gutter_width` adds it while `buffer.signs?` (`:144`). `FramePresenter#number_shown` (`carat/adapters/frame_presenter.rb:961`) subtracts it to find the number column, and `paint_row` (`:1011`) fills that many cells with `SignColumn`, cuts the glyph to that many characters, and starts the numbers after it. Every other reader (`ArrangeView` for the cursor and the text width, `ShowCompletionDocs`, `SplitWindow`'s minimum width) goes through `gutter_width`. Every glyph the icon sets give a sign (`Icons`, the nerd, unicode, and ascii sets) is one character of one cell.

## Goals / Non-Goals

**Goals:**
- One sign cell, as the Facet plan's round 3 fixed it: the glyph in its kind's group, a blank in `SignColumn`, and the numbers or the text one cell nearer.
- The `lh` bench held: no allocation or round added on the paint path.

**Non-Goals:**
- An `option.signcolumn` setting (auto, yes, no) and choosing the most severe sign when git and the diagnostics mark one row; the first registered owner still shows, as today.

## Decisions

- Change the one constant, `SIGN_WIDTH = 1`, and keep every reader on it, so the gutter, the cursor, the text width, and the split minimum follow from one place. Alternative: drop the constant and write 1 in place; rejected because the presenter and the window must agree, and the constant names that agreement.
- Keep the glyph cut in `paint_row` (`sign[0, SIGN_WIDTH]`), now to one character, so a plugin's glyph of several characters cannot spill into the number column. It cuts by characters, not cells; every shipped glyph is one cell, so it is exact for them.
- With numbers off, the text starts in the cell after the sign, as Neovim's one-cell `signcolumn=yes:1` draws it.

## Risks / Trade-offs

- A glyph of two cells (an East Asian wide character a plugin passed itself) would overlap the first number cell; no shipped icon is one, and the place_sign request takes icon names, not glyphs, so only a direct domain caller could pass one.
- Rows painted before the change are repainted anyway: the gutter width is part of each row's record in `PaintedRows`, so the narrower gutter repaints every row of a window with signs once.
