# Design

## Context

`TabBar#paint` (`carat/adapters/tab_bar.rb`) and `Winbar#paint` (`carat/adapters/winbar.rb`) write only group ids; the colors come from `Themes::GROUPS` (`carat/domain/themes.rb`), where `TabLine` is `DIM` on `PANEL_NC`, `TabLineSel` `FG` on the editor background in bold, and `TabLineFill` `PANEL_NC`. `PANEL_NC` sits about 1.1:1 from one_dark's background, and with `option.background terminal` the selected tab is the terminal's own background. The scout pack `tmp/scout/rendering-8b4c26a-...md` holds the call sites; every line it cites was re-read on main at 8b4c26a and holds.

## Goals / Non-Goals

Goals: the selected tab reads at a glance (3:1 against the row, bold), the modified mark has one fixed cell, the winbar has the accent and ` › ` (` > ` in ASCII), one digit fit. Non-goals: the parts queued as `winbar-outline`, new groups, palette colors other than the tab group's roles.

## Decisions

### TabLineSel takes the normal pill's roles

`TabLineSel` becomes `ON_STRONG` on `BLUE`, bold at every depth, the same roles as `StatusLineModeNormal`, whose text contrast every palette already passes. Its background against `PANEL_NC` (the background of `TabLine` and `TabLineFill`) is 4.8:1 in one_light and above 5:1 in the others; at 16 colors blue (4 or 12) against `PANEL_NC`'s 7. Both backgrounds are palette roles, so the block reads the same with the terminal's background. The alternative, two new groups `WinBar` and `WinBarNC`, would renumber every syntax, icon, and markup id for no gain: the current winbar already uses `TabLineSel`, so it takes the accent with the tabs.

### The selected tab's icon in TabLineSel

A file-icon group has no background, so on the accent it would cut a hole in the block, and its hue against blue is not held to any ratio. The selected tab draws its icon in `TabLineSel`; the other tabs already draw theirs in `TabLine`. `icon_group` and the plugin API require go away from the tab bar.

### One cell for the mark

`tab_width` counts the mark slot as one cell whatever the buffer's state, and `paint_tab` writes the mark through `mark(set)`: the set's `modified` glyph when `DisplayWidth` measures it one cell, the ASCII `*` otherwise. Both are stored strings, so no object is made. Every shipped glyph measures one cell today, so the fallback guards a future glyph; the visible effect is that toggling the modified state never moves the next tab.

### The separator as two constants

`Winbar::SEPARATOR = " › "` and `ASCII_SEPARATOR = " > "`; `paint` takes a fifth argument, `ascii`, which `FramePresenter#paint_winbars` passes as `options.icons == "ascii"`, read once in `call`. The presenter still reads the state only. `Icons` is not used because the nerd set holds private-use glyphs only and `›` is in every font.

### One digit fit on Frame

`Frame#put_digits_within(row, col, number, hl, limit)` writes the digits only when all fit before `limit` and returns the column after them, or `col` unchanged. `StatusBar` (four calls) and `TabBar` (the counts and the tab-page numbers) call it; their private copies are removed. The room the overflow counts reserve (`tab_bar.rb:53`) keeps its arithmetic and now names the fit it reserves for.

## Risks / Trade-offs

- Snapshots of frames holding the tab row or a winbar change in their groups and the ` › ` text; each diff is read before it is kept.
- The accent block on the current winbar spans its path and symbols; a long path is a long block, which is the intended reading of "the current window".
