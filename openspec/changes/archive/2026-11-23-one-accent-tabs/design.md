# Design

## Decisions

- `TabLineSel` takes the roles FG on BG, bold at both attribute depths, so with the theme's background the selected tab is Normal's colors in bold and with the terminal's it is bold alone.
- `TabLineName` is the new role TAB_NAME (each palette's text color, black at 16 colors) on PANEL_NC, bold: the tab row, winbar, and header bars keep their `TabLineFill` panel color, and a name in this group reads on it at 24 bits, 256, and 16 colors (black on the bar's light gray at 16).
- `TabBar#bare=` (a plain writer, set by `FramePresenter` from NO_COLOR or 16 colors) skips the row's fill and draws unselected names and counts in `Normal`; the selected tab and the current page number use `TabLineSel`.
- The tab icon leaves `paint_tab`, `tab_width`, and `span_width`; `FRAME_CELLS` drops to 4. Nothing else read the icon from the tab.
- No allocation is added: groups are integers, and the new helpers return them.
