# Design

## Context

`FramePresenter#paint_separators` puts one glyph column after every child of a row but the last, including between a sidebar and the editor, and a sidebar window is painted like any window, so its cells carry plain group ids. A frame cell carries a group id plus a layer (cursor line, float); `Theme` resolves each layer at build time and `SgrTable` loops `Highlight::LIMIT` ids.

## Goals / Non-Goals

**Goals:**
- A sidebar on `PANEL_NC` with no glyph where it meets the editor; `│` kept between two editor windows, in BORDER.
- An edge still visible at 16 colors and under NO_COLOR.

**Non-Goals:**
- The bottom panel's background, the tab row, and the separator row under a stacked window (unchanged apart from the group's color).

## Decisions

- A third layer, `SIDEBAR_LAYER = COUNT * 3`, built in `Themes.from_palette` as the cursor-line layer is, on `PANEL_NC`. A layer fits the frame's cell model, the painted-row record (the layer is already one of its inputs) and `SgrTable` without a new cell field. The sidebar's cursor row keeps `CURSOR_LINE_LAYER` (one layer per cell), so the cursor line shows over the sidebar as in the editor.
- `Frame#lift` lifts only cells below `COUNT`, so any layer is added to a plain group's id and never to a cell already on a layer.
- 16 colors: the layer equals the group. The dark palettes' text is basic 7 or 8 on a basic 0 background, and `PANEL_NC` is basic 7, which would hide the text; no basic color is darker than 0. So at 16 colors the edge is the glyph, in BORDER (basic 8). NO_COLOR has no background change at all, so it keeps the glyph too. Both are named in `docs/design.md` first, as its header asks.
- The presenter learns the 16-color depth by a `basic_colors=` setter next to `plain=`, set once at `open`, since only the terminal knows the depth.
- `WinSeparator` becomes `BORDER` as `docs/design.md` says; Carat's two palettes fall under 3:1 (1.66:1 and 1.54:1), so they take their own floor like `FloatBorder`; the other four palettes' `BORDER` equals their `FAINT`, which already passes.
- The separator column's blank cell is written every frame (the separators are compared cell by cell), so a glyph left in the frame by an earlier layout or setting is overwritten.
