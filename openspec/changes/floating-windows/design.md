# Design

## Context

A tab page (`Domain::TabPage`) holds a layout tree, its current leaf, and the previous one; `TabPage#window` is what `EditorState#window` and so every use case reads as the current window. `ArrangeView` lays out the current tab page before every render. `FramePresenter` paints each window's rows into the back of two frames, skipping a segment (one row of one window) whose `PaintedRows` record says it already shows the same thing, marks a row dirty when it differs from the frame shown, and records a scroll for a full-width window, which `ScreenPresenter` sends as a scroll region. Chrome rows (status bar, message row, separators) are painted every frame and compared cell by cell. No float, border, or z order exists (scout packs for areas 11, 13, and 15).

## Goals / Non-Goals

**Goals:** floats with no cost to a key when none is open; with a 60 by 15 float open, at most 20 microseconds and 3 allocations per key above `lh`; window rows under a float repainted only when the float's rectangle changes.

**Non-Goals:** the popups that will use floats; a float spanning tab pages; floats in the layout's window numbering.

## Decisions

### A float is a window plus a spec, held by a layer on the tab page

`FloatSpec` is a `Data` value (anchor `"editor"` or `"cursor"`, row, col, height, width, border, title, z). `FloatWindow` is a `Struct` of a `Window` and its spec; the window's rectangle is the text area, the border around it. `FloatLayer` keeps the floats in an `Array[untyped]` with a typed `at(i)`, as `PluginEntries` does, sorted by z with a new float after floats of the same z, and the index of the focused float, -1 for none. The window gets an id from `TabList#adopt`, so plugins and `focus_window` address it like any window. Alternative: floats as layout leaves with a flag; rejected, since every layout walk (numbering, neighbours, equalize, close) would have to skip them.

### Focus is an index on the layer

`TabPage#window` answers the focused float's window when the index is set, else the layout's current leaf: one integer test on the hot path. `TabPage#focus(id)` leaves the float first, so every use case that focuses a leaf (split, side window, a plugin's focus, `:b` finding a window) leaves it. `FocusWindow` in a float only leaves it; `CloseWindow` and `Quit` close the focused float instead of a layout window, so `:q` in a float never ends the editor. `SplitWindow` leaves the float before splitting.

### Placement at arrange time

`ArrangeView` places each float after the layout: the anchor point is (0, 0) for `"editor"` and the cursor cell of the layout's current window for `"cursor"`; the box (text plus border) is clamped to the rows above the message row and the screen's columns, its size first, then its position. The float's window then scrolls to its cursor like any window.

### Painting by z with a float key

After the windows, separators, status bar, and start screen, `FramePresenter` paints each float in layer order: text rows through the same `paint_text` the windows use, filled with `NormalFloat`, then the border (`╭─╮│╰╯` in `FloatBorder`) and the title cut to the top edge in `Title`. Each frame keeps a float key, eight integers per float: the box (top, bottom, left, right), the first row and column the float shows, and its buffer's two change counters (`closed_count`, which only grows, and `changes`).

- When the back frame's key differs from the one to paint, `PaintedRows#forget` drops the segments of every row the back frame's floats covered, so those window rows are repainted, and every float row is painted.
- When it is the same, a window segment that is unchanged is skipped and the float cells over it are still exact, so only the float rows over a row painted again in this frame (a changed window row, a separator row, the status bar, the tab line) are painted again. A split layout (vertical separators are painted every frame), the start screen, or a focused float (the cursor's visual highlight) paints every float row.
- When the key equals the shown frame's key, the float cells equal the shown frame's and no row needs a comparison for them; otherwise every row of a box of either key is compared cell by cell from the column before the box to the one after it (`Frame#same_cells?`), the edge cells being where a cut wide character is blanked.
- A window whose rows meet a box of either key records no scroll.
- With no float in the layer and none in either frame none of this runs: one count and two length tests per frame, and one flag test per painted row.

Measured with `make bench SCENARIOS="lh lh-float"`: `lh` 14.5 microseconds and 27 allocations per key, `lh-float` (a bordered 60 by 15 float over the middle of a 60 by 200 screen, the cursor row under it) 15.0 microseconds and 27 allocations. An earlier version that painted every float row and compared every covered row in full each frame took 47.4 microseconds.

Alternative: forget the covered segments every frame; rejected, it repaints 17 rows of 200 cells per key while a float is open.

### Esc and the action

`float.close` is a `FloatHandler` over `CloseFloat`, which closes the topmost float of the current tab page and does nothing when none is open; `<Esc>` in normal mode is bound to it in `config/default.caratrc`, so a plugin or user binding can replace it.

### Plugin requests (API 2.3)

`PluginApi::FloatOptions` is a `Data` value with the spec's fields plus `enter`; the anchors are checked by `Domain::FloatSpec.refusal`, the one place the rule lives, and named in the value's comment. `open_float(options, lines)` validates the anchor, a size of at least 1 by 1, and a z from 0 to 1000, copies the lines and the title, opens a scratch buffer owned by the plugin (outside the buffer list) in a float through `OpenFloat`, and answers its window id; a full layer fails. `move_float(window, row, col)` and `close_float(window)` find the float in any tab page and fail for an unknown id or another plugin's float. They live in `WindowRequests` beside the other window requests, each with its `PluginLink` override; `MINOR` becomes 3.

## Risks / Trade-offs

- [A float's buffer is outside the buffer list, so `:ls` and `:b` do not see it] → intended: it is a view a plugin owns; `:w` in it fails as in any scratch buffer.
- [A disabled plugin's floats stay open] → Esc closes them; the backlog keeps closing them on disable.
- [A buffer change the counters miss would leave a float stale] → every text change closes a transaction, which `closed_count` counts; `test/editor_floats.rb` compares the screen after edits under a float with a full repaint.
- [A screen too small for a float's border] → the float is not painted while its box does not fit.
