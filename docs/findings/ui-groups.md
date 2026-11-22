### Status bar has no folder segment and shows the server state as text
- Location: `carat/adapters/status_bar.rb` (`collect`, `paint_entry`, the `LSP` kind), `docs/design.md` section 8 (Status bar)
- Why: the design lists folder among the quiet segments and says the server state is one dot; the bar has no folder segment and the `lsp` slot is its name and state text, so those two parts of the design are not drawn.
- Fix: add a folder segment (a `StatusSlots` field a plugin or the project root fills) in `StatusLineDim`, and draw the server as one dot in its state group with the name in `StatusLineDim`; keep the `lsp` width table and `docs/compatibility.md` in step.

### The progress bar and the percent keep StatusLine
- Location: `carat/adapters/status_bar.rb` (`paint_bar`, the PERCENT and PROGRESS kinds)
- Why: the undone cells of the progress bar and the percent are drawn in the bold `StatusLine` beside quiet neighbours, while the design's hierarchy names only the file and the position as leading; the brief named the design's groups, so these were left as they were.
- Fix: draw the undone cells and the percent in `StatusLineDim` once the design says which; update the progress and percent scenarios and snapshots.

### The visual indicator is dim but ModeMsg and MoreMsg are still unused
- Location: `carat/adapters/frame_presenter.rb` (`paint_message`), `carat/domain/themes.rb` (`MESSAGE_MODE`, `MESSAGE_MORE` rows)
- Why: the `-- VISUAL --` indicators now use `MsgDim`, so `ModeMsg` (bold) has no caller and `MoreMsg` still has none; the theme rows are dead until a change uses or drops them.
- Fix: either draw the indicator in `ModeMsg` with a dim row, or remove the two groups with the renumbering, and add a `-- More --` pager only with a change that needs it.

### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes
- Location: `test/adapters_status_bar.rb`, `test/domain_theme.rb`, `carat/drivers/ansi_terminal.rb`
- Why: the tests assert the bar's cell groups under the presenter's plain mode and the group's 16-color and 256-color theme entries; no test writes the bar through the ANSI driver at 16 colors or with `NO_COLOR` to read the escape sequences, so a regression in how the driver maps `StatusLineDim` would not show.
- Fix: add a smoke case that draws the bar through the driver at 16 colors and under `NO_COLOR` and compares the written sequences for `StatusLine` and `StatusLineDim`.
