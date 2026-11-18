## Why

Carat's two palettes miss the Facet plan's contrast targets in the places read on every keystroke: the float border is a text-gray FAINT held to 3:1, so it competes with the float's text; light Search (1.31:1) and Selection (1.26:1) barely show on the light background; the current match is never drawn apart from the other matches, the `CurSearch` group having no painter; at 256 colors carat-dark's panels and background both become index 234, so the panel edges vanish; and the command pill is yellow, the search gold, against the plan's accent meanings (cyan for a query). The user accepted the design council's Facet plan; this is its wave 1 item 4.

## What Changes

- The palettes gain three color roles, reusing guide-colors' pattern: BORDER, which colors `FloatBorder` (carat-dark #3b4157, carat-light #c9cdd9, basic color 8); PANEL_DIM, secondary text on the status bar's background (carat-dark #a4aabd, carat-light #5c6173), not yet used by a group; and ON_SEARCH, the text on the soft search tint (carat-dark #c8ccd8, carat-light #2f3340, black at 16 colors). The other four palettes keep their look: BORDER takes their FAINT, ON_SEARCH their ON_ACCENT, PANEL_DIM their PANEL_FG.
- In carat-dark and carat-light `FloatBorder` leaves the 3:1 decoration floor, as the guides did, and stays apart from the float's background by at least 1.3:1; the other palettes' borders keep 3:1.
- Search softens to a tint the text keeps reading on: SEARCH #4a4129 / #f7e3a1, `Search` and `Todo` drawn in ON_SEARCH.
- The match under the cursor, in every window, is drawn in `CurSearch` (the strong orange INC_SEARCH, bold) while "hlsearch" shows the matches, as Neovim draws it.
- carat-light's SELECTION becomes #c5cff0 (1.50:1 on the background, was 1.26:1); its panel surfaces PANEL_NC and FLOAT become #eceef3, a step of 1.12:1 from the background (was 1.09:1).
- carat-dark's PANEL_NC is pinned to index 233 at 256 colors, apart from the background's 234.
- `StatusLineModeCommand`, the pill of the command line and of every query picker's prompt, is cyan in every palette.
- The start screen's sparkle is drawn in `Title`, sapphire, in place of `Type`.
- Roadmap: outside the numbered roadmap of `docs/architecture.md` section 12; a user request from the Facet plan (wave 1 item 4).
- Out of scope: the match count on the command line (Neovim's searchcount `[3/12]`), split off by the plan as `search-count`; a group using PANEL_DIM (the status bar's dim text comes with `ui-groups`); BORDER on `WinSeparator`; pinning carat-dark's FLOAT at 256 colors; new colors for one_dark, one_light, dark_plus, and light_plus beyond the cyan pill.

## Capabilities

### New Capabilities

### Modified Capabilities
- `color-themes`: the float border, the search tint, the panel and selection colors, and the command pill of Carat's palettes; the float border's own contrast rule.
- `search`: the match under the cursor is drawn in `CurSearch`.
- `start-screen`: the sparkle carries `Title`.

## Impact

- Domain: `Themes` (roles BORDER, PANEL_DIM, ON_SEARCH in every palette; FloatBorder, Search, Todo, and the command pill remapped; carat-light SELECTION, PANEL_NC, FLOAT; carat-dark PANEL_NC at 256), `StartArt` (the sparkle's group).
- Adapters: `FramePresenter#paint_matches` draws the match holding the cursor in `CurSearch`.
- Tests: `test/domain_theme.rb` (role rows for both palettes, the border's floor, the cyan pill), `test/adapters_frame_presenter.rb` (the bold current match), `test/editor_search.rb` (hlsearch with the cursor on a match), `test/editor_start_screen.rb` (the sparkle's group).
- Docs: `docs/compatibility.md` (UI groups, search highlighting).
- README.md: unchanged, it names no palette color, group, or pill color.
- docs/architecture.md: unchanged, it names neither the palette roles nor the search groups' painting.
- Assumptions: the queue line's "light PANEL #eceef3" is the designer's proposal for the light panel surfaces PANEL_NC and FLOAT (designer.md lists PANEL #e3e6ef as kept); the stronger light SELECTION is #c5cff0, meeting the researcher's 1.5:1 on the background, 1.3:1 on the cursor line, and 7:1 for text; the current match is the match holding the cursor in each window, as Neovim's CurSearch; the query pickers' prompts already draw the command-line pill, so the one group covers them.
