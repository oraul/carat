# Design

## Context

`ArrangeView#place_floats` places every float at each arrange, so after a show and after a resize (`EditorAssembly#render` resizes the state, then arranges), through `FloatWindow#place(top, left, rows, cols, edged)` on the area above the message row. `place` cuts the box to the area and moves it in with no margin, so floats touch the screen's edges, the buffer tabs, and the status bar. The palette is the only centered float, and it computes its column once at show, `(cols - width - frame_width(1)) / 2`, which assumes a drawn edge: under `winborder none` it is one column left of center, and a resize keeps the old column. `place` also binds a local `edge` that shadows the struct's reader. `FloatWindow.text_room(cols, border, style)` is called with `border` true by all five callers. Notification titles are put at `left + 1`, flush to the corner, while `paint_title` centers a float title with a blank on each side. A plugin cannot read `option.winborder`, so the finder lays its boxes out for a bordered frame of 4 (`FRAME`) and its boxes stand 2 columns apart under `none`. `WindowRequests#open_float` and `#move_float` pass a plugin's row and column straight into the spec; `place` adds them to the anchor cell, so an offset near the integer maximum wraps past `shift`.

## Goals / Non-Goals

Goals: one margin kept by `place` for every float, counted by `text_room`; a centered float placed by `place` itself; notice titles drawn by the float-title code; the frame readable through the plugin API; offsets range-checked at the plugin boundary; the comments and map bullets current.

Non-goals: the key hints panel, the palette's columns, and the completion popup's padding (`menu-hints`); moving notifications; a new anchor value; centering for plugins.

## Decisions

### The margin lives in place

`FloatWindow::MARGIN = 1`. `place` cuts the height to `rows - 2 * MARGIN - 2 * edge` and the width to `cols - 2 * MARGIN - frame_width(edge)` (at least one cell, as before), then `shift` keeps the corner between `MARGIN` and `room - MARGIN - size`. When a box with its margin is larger than the area on an axis (a screen too small), `shift` keeps it between 0 and `room`, as before, so a tiny screen loses the margin, not the float. The area stays the screen above the message row, so the margin rows are the top row (the buffer tabs when shown) and the row above the message row (the status bar). Alternative: a margin per caller (the palette's row 1, the finder's `MARGIN`); rejected, since the user asked it of every float and `place` is the one place every float passes.

`text_room(cols, style)` is `cols - 2 * MARGIN - frame_width(edge)` with the edge from the style; the border argument is dropped, every caller sizing a bordered float. A float sized to the screen therefore fills the screen less its margin and is never cut by `place`.

### Centering is a placement flag

`FloatWindow` gains a `centered` member, false from the constructor; the palette sets it after building the float, as it sets `selected`. When it is true `place` ignores the spec's column and takes `(cols - box width) / 2`, the box width counting the edge `place` has just chosen, then moves it inside the margin like any corner. Because `place` runs at every arrange, the palette is centered at show and again after a resize, under every border style, with no resize handler. Alternatives: a `"center"` anchor (the queue and the user's report rule out a new anchor value) or a `centered` member on `FloatSpec` (it would reach `FloatOptions` through the plugin path, a major version); rejected.

### The FloatOptions choice: a frame request, 2.6

`FloatOptions` has required members, so a new member is a major version (`docs/architecture.md` section 9.4). The plugin API instead gains `Host#float_frame(border)`, answering `PluginApi::FloatFrame` (`ok`, `message`, `edge`, `padding`, `margin`, with `box_width(width)`), through a `PluginLink` override and `WindowRequests#float_frame`, which reads `option.winborder` and `FloatWindow::PAD` and `MARGIN`. `VERSION` becomes 2.6, a minor bump: a 2.5 plugin is accepted unchanged. The finder asks for the bordered frame at each refresh and lays its boxes out from `box_width(0)` and `margin`, so the preview box starts in the column after the list box under every style. The `FloatOptions` comment and the `open_float` row of `docs/plugins.md` give the padding, the box width, and the margin.

### Offsets are refused at the boundary

`FloatSpec::OFFSET_MAX = 10_000` and `FloatSpec.offset_refusal(row, col)` ("No offset N: -10000 to 10000", the row first). `FloatSpec.refusal` takes the row and column too and calls it, so `open_float` refuses an out-of-range offset; `move_float` calls `offset_refusal` before it looks the float up. The core floats compute their offsets from the screen and the cursor, so the check stays at the plugin boundary. The bound is far past any terminal and keeps `top + spec.row` far from the integer limits.

### Notice titles share paint_title

`paint_title(frame, r, left, last, title, hl)` takes the highlight; floats pass `FloatTitle`, notifications the severity's group (Normal when plain). A 20-column notification has room for the longest title, `Warning`, with its blanks.

### The edge reader

`place` writes `self.edge` first and reads the reader afterwards, so no local shadows it.

## Risks / Trade-offs

- Every float sized to the screen is 2 columns narrower, and a box at an edge moves one cell in: the hover wraps at 74 columns on an 80-column screen instead of 76. This is the margin the user asked for.
- A cursor-anchored float on the first or last column moves one cell off its anchor.
- A plugin built against 2.5 that computes boxes from `width + 4` still works; it only misses the frame under `none`.

## Migration Plan

None: no option or binding changes; the plugin API change is additive (2.6).
