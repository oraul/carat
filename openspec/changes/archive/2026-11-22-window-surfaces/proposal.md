# Proposal

## Why

`docs/design.md` (section 1, Edges by background, and the Surfaces rule) decides that two surfaces meet where their backgrounds change, with no glyph, the sidebar being darker than the editor, and that a line is drawn only between two windows of the same color, in the quiet BORDER tone. Today a sidebar window is painted on `Normal` like the editor, so the explorer is separated from the file by a `WinSeparator` glyph column, and that group is `FAINT`, not `BORDER`. The change is the design council's decision for window surfaces (wave 3 of the Facet queue), the user's request.

## What Changes

- Add a sidebar layer of highlight groups (`Highlight::SIDEBAR_LAYER`, above the float layer, `LIMIT` growing to four layers): a group in it keeps its foreground and attributes and sits on `PANEL_NC`, the darker panel background every palette already has, unless the group has a background of its own; a plain `Normal` cell with the terminal's foreground takes the palette's text color, as on the cursor line. At 16 colors the layer is the group itself.
- Draw every fixed-width sidebar window's rows, gutter and tilde rows included, on the sidebar layer (`FramePresenter#paint_window`); the cursor line keeps its own layer on the sidebar's cursor row.
- Draw no glyph where a sidebar meets the editor: the separator column between them is a blank cell of the sidebar layer. Two editor windows side by side keep `│` (`|` with ascii icons) in `WinSeparator`.
- Keep the glyph at the sidebar's edge where the background cannot show it: under NO_COLOR (`plain`) and at 16 colors (the new `FramePresenter#basic_colors=`, set at `open` from the terminal's depth).
- Change the `WinSeparator` group from `FAINT` to the `BORDER` role, the quiet tone of the design. Carat's palettes (BORDER 1.66:1 and 1.54:1 on the editor background) leave the 3:1 decoration floor for their own 1.5:1 rule, as the float border does; the other four palettes' BORDER is their `FAINT` and keeps 3:1.
- Make `Layout#sidebar?` public, and let `Frame#lift` lift only a plain group's cell, so a cursor-line cell is never lifted twice.

Assumptions: only the left and right sidebars (fixed-width windows) are surfaces here; the bottom panel keeps `Normal` and its separator row; the blank column after a sidebar belongs to the sidebar's layer (one cell of padding inside the surface); the 16-color edge is the glyph rather than a darker background because the basic set has no background that keeps every text color readable on both dark and light themes (the dark themes' text is basic 7 and 8 over a basic 0 background); `docs/design.md` gains one sentence for that fallback, as its header asks.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the separator column between windows, the sidebar's surface.
- `color-themes`: the sidebar layer, `WinSeparator` as the border tone, and the contrast rules that exempt it.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/adapters/editor_assembly.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/domain/frame.rb`, `carat/domain/layout.rb`.
- Tests: `test/adapters_frame_presenter.rb`, `test/domain_theme.rb`, `test/editor_explorer.rb` and the snapshots.
- Docs: `docs/design.md` (the 16-color and NO_COLOR edge), `docs/architecture.md` (the layer list), `docs/compatibility.md` (the window separators), `docs/codebase-map.md` (areas 4 and 13), README.md (the sidebar sentence).
