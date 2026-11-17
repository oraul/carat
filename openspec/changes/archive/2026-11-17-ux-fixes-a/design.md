# Design

## Context

`Themes::GROUPS` names each group's foreground and background role; the three `StatusLineLsp*` groups name `NONE` as their background, so they show the terminal's background, or the editor's when the theme paints it, while `StatusLine` names `PANEL`. The status bar adapter draws the `lsp` slot and the progress bar's done cells in those groups. The finder plugin learns of Enter through `on_input`, which `PluginRouter#answer` calls after the host closed the prompt and set normal mode (`ExecuteCommandLine` sets the mode first), so the plugin may open its live prompt again from there. `FollowPalette#rows` and `#styles` lay out a row as name, description, key and style it by character columns.

## Goals / Non-Goals

Goals: the status bar is one band whatever the server's state; a typo in the finder costs only its correction; a palette row reads as a sentence first, keeps the dotted name for configuring keys, and marks a cut. Non-goals: the palette's unfiltered order, a message on Enter with no match, the other ux-pass findings.

## Decisions

- Three palette roles, `PANEL_YELLOW`, `PANEL_GREEN`, `PANEL_RED`, the state accents on the bar, rather than the editor's accents on `PANEL`: measured on the bar, the editor's accents fall under 4.5:1 in four palettes (one_dark's red 3.4, one_light's yellow 4.3 and green 4.1, and every accent on dark_plus's and light_plus's blue bar, down to 1.1), so each palette gives its own. carat-dark and carat-light keep their accents (all pass); one_dark keeps yellow and green, its green with the 256-color index 150 since the nearest index falls to 3.9:1, and lightens red to `#f5a3a8`; one_light darkens to `#7a5700`, `#2f6b2e` (index 22, the nearest being a gray), and `#b8103c`; carat-light's green takes index 22 for the same reason; dark_plus and light_plus, whose bar is VS Code's blue, take light tints `#ffe58f`, `#c0f5bc`, `#ffdcdc`. At 16 colors the accents are the basic dark yellow, green, and red (3, 2, 1) over a light gray bar (7) and the bright ones (11, 10, 9) over the blue bar (4). Alternative rejected: drawing the slot in `StatusLine`'s own text color, which loses the state at a glance.
- The finder reopens its live prompt with the typed text in `on_input` when Enter comes with no match, keeping its list, matches, and floats; when the reopen fails it closes as before. No host request is added and the plugin API stays the same.
- The palette row becomes label, name, key: the label column takes `width - 42` cells, the name column 30 cells in `PmenuExtra`, the key 12 cells. When the label would get under 20 cells (a text width under 62) the name is left out and the label takes `width - 12`; this replaces the old rule that dropped the description under 2 cells. A text wider than its column keeps `column - 2` cells and then the mark, `…` or `>` under `option.icons ascii`, both one cell, then the padding space, so the columns still start at the same cell. The marks of the match stop before the cut mark.

## Risks / Trade-offs

- The light tints on dark_plus's and light_plus's blue bar are paler than the editor's accents. Accepted: they are the only colors that read at AA on that blue, and the state stays distinct by hue.
- A user who learned the palette's name-first rows sees the order change. Accepted: the user asked for the readable label first, and the name keeps its place in the row and in the filter.

## Testing

`test/domain_theme.rb` checks every palette's `lsp` groups share `StatusLine`'s background at every depth and with either background choice, and passes the contrast table on their own background; its table of one_dark's status groups gives the new colors. `test/editor_finder.rb` checks `<C-p>zzqx<CR>` leaves the prompt `> zzqx` and the float `No match`, and that the kept query can be corrected and opened. `test/editor_palette.rb` checks the label at cell 0, the name 42 cells from the end, the key 12 cells from the end, the cut mark, the ascii mark, the narrow palette without the name, and the groups of the name and description columns. `make bench` holds the recorded allocations.
