## Context

The palettes are rows of a role, its 24-bit color, its 256-color index, and its 16-color index (`carat/domain/themes.rb`); `GROUPS` maps every highlight group to a foreground and a background role, the same for every palette. guide-colors added the GUIDE and GUIDE_SCOPE roles and took Carat's guides out of the 3:1 decoration floor in `test/domain_theme.rb`; this change follows that pattern. The frame presenter paints every match of the highlighted pattern in `Search` (`FramePresenter#paint_matches`); `CurSearch` has theme colors but no painter.

## Goals / Non-Goals

**Goals:**
- Give Carat's palettes the Facet plan's values for the float border, the search tint, the light selection and panels, the 256-color panel index, and the dim bar text; the command pill cyan; the sparkle sapphire.
- Draw the match under the cursor in `CurSearch`, strong and bold.

**Non-Goals:**
- The match count on the command line (`search-count`), a group using PANEL_DIM (`ui-groups`), BORDER on `WinSeparator`, any other palette's colors beyond the shared cyan pill.

## Decisions

- Three new roles, BORDER, PANEL_DIM, and ON_SEARCH, appended after GUIDE_SCOPE so no role number moves. ON_SEARCH is added because the brief's dark tint #4a4129 is dark: ON_ACCENT (the background color) would not read on it, and the plain FG role is dropped with the terminal's background and is light gray at 16 colors over bright yellow. ON_SEARCH is FG's color at 24 bits and 256 colors and black at 16, where the tint stays bright yellow. The other palettes take their ON_ACCENT for it, so they draw as before. `Todo`, which shares the SEARCH background, takes ON_SEARCH too.
- The other palettes' BORDER is their FAINT and their PANEL_DIM their PANEL_FG (their DIM is below 4.5:1 on their bars: one_dark 3.53:1, dark_plus 1.81:1), so nothing they draw changes.
- Carat's float border leaves the 3:1 floor with a visibility floor of its own, 1.3:1 on the float's background at 24 bits and 256 colors (carat-dark 1.77:1 and 1.74:1, carat-light 1.36:1 and 1.32:1, rounded down), checked in `test/domain_theme.rb` beside the guides' order.
- The light panel value #eceef3 goes to PANEL_NC and FLOAT, the pair the designer's note proposes it for; PANEL, the active status bar, keeps #e3e6ef. Light SELECTION #c2ccef: 1.54:1 on the background, 1.44:1 on the cursor line, text 7.90:1 (the researcher's 1.5, 1.3, and 7).
- carat-dark's PANEL_NC gets the explicit 256 index 233; FLOAT, the same 24-bit color, keeps its nearest index (out of scope).
- The current match: `paint_window` hands `paint_matches` the cursor's column on the cursor's row (none on a closed fold's row), and a match whose code points hold it is filled with `CurSearch` in place of `Search`, in every window, as Neovim's CurSearch follows each window's cursor. The row cache already keys on the cursor's column per row and on the drawn stamp, so moving the cursor repaints exactly the rows whose current match changes; no new cache field.
- The command pill: `StatusLineModeCommand` maps to CYAN in `GROUPS`, so every palette's pill turns cyan; plugin prompts (the finder and the other query pickers) run in the command-line mode and draw the same pill.
- The sparkle takes `Title`, whose foreground is the palette's BLUE, sapphire in Carat's palettes, in every palette.

## Risks / Trade-offs

- [The light search tint #f7e3a1 is 1.23:1 on the background, below the old 1.31:1] → the plan's decision 3 is a soft tint with a strong current match; the matches stay told apart by the strong orange current match and by the tint's hue.
- [The command pill changes in the four other palettes too] → `GROUPS` is shared by design; cyan passes 4.5:1 under ON_STRONG in all six (lowest light_plus 5.10:1).
