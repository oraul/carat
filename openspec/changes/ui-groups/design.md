# Design

## Context

`StatusBar#paint` collects the present segments into parallel integer arrays, fits them to the width by priority, then paints the left group (kinds MODE to DIAGNOSTICS) from column 0 and the right group ending at the right edge; each segment is a space, its text, and a space in one group, `StatusLine` unless it is the pill, a count, or the `lsp` slot. A group's colors come from `Themes::GROUPS` rows of roles, the roles from each palette's rows (24-bit, 256-color index, 16-color index).

## Goals / Non-Goals

**Goals:**
- The bar's quiet text in its own group and role, readable at 4.5:1 at every depth, with the lead in bold `StatusLine`.
- The spacing of `docs/design.md`: two cells after the pill and between a label and its detail, three between independent groups.
- The message row's visual indicators dim.

**Non-Goals:**
- A folder segment, the one-dot server state, the progress bar's colors, the selected tab's fill, `MESSAGE_MODE`, `MESSAGE_MORE`, and any driver change.

## Decisions

- One new role `PANEL_DIM` and one new group `StatusLineDim` (UI group after `Folded`, the later ids moving up by one as when `Folded` was added). The group is `PANEL_DIM` on `PANEL` with no attributes, so it shares the bar's background like the `lsp` and count groups. Its 16-color index is the one of `PANEL_FG` in every palette (black on the light gray bar, white on `dark_plus` and `light_plus`'s blue bar): a basic color that reads at 4.5:1 under xterm's colors, the weight carrying the difference from the bold `StatusLine`.
- PANEL_DIM values: the design's for the carat themes (5.4:1 and 4.93:1 on their `PANEL`); `#b0b6c2` for `one_dark` (4.79:1), `#5c5f6a` for `one_light` (5.06:1), and `#e0ecf5` for `dark_plus` and `light_plus` (4.88:1 on their `#0068ad` bar). Every value is measured by `test/domain_theme.rb` at 24 bits, 256 colors, and 16 colors.
- The gap is part of each segment's width, added in `add` by `gap?(kind)` and painted as one `StatusLine` cell before the segment, so `fit` and the right-aligned group need no other change and the pass stays allocation-free. The pill and the file are two cells apart (the pill's closing space and the file's leading one) and so are the position and the percent; the cell is not added before them. Alternative: a gap after each segment, which would also push the last segment from the right edge.
- Which segments are quiet follows `docs/design.md` section 8: branch, file type, encoding, and the server; the `lsp` slot keeps `StatusLineLspStarting`, `Ready`, and `Error` for its states and takes `StatusLineDim` for the states that had `StatusLine`. Plugin segments and the progress label stay `StatusLine`, since a plugin's text may carry the status a user must see.
- The visual indicators take `MsgDim`, the group of the pending keys beside them; the diagnostic of the cursor line and the other messages keep their groups.
- NO_COLOR: the bar's cells keep their groups, as the progress bar's undone cells and the message row do; the terminal side maps groups to colors (the frame presenter's plain mode only picks ASCII glyphs), so `carat/drivers/ansi_terminal.rb` is not edited.
