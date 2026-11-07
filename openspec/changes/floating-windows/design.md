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

After the windows, separators, status bar, and start screen, `FramePresenter` paints each float in layer order: text rows through the same `paint_text` the windows use, filled with `NormalFloat`, then the border (`╭─╮│╰╯` in `FloatBorder`) and the title cut to the top edge in `Title`. Each frame keeps a float key, four integers per float box (top, bottom, left, right). Before the windows are painted, when the back frame's key differs from the current one, `PaintedRows#forget` drops the segments of every row the back frame's floats covered, so those rows are repainted under the moved or closed float; when the key is the same, a segment that is unchanged is skipped and the float is painted over it again, which is exact because the float covers the same cells. Every row covered by a float in the key or in the shown frame's key is added to the chrome rows and compared cell by cell. A window whose rows meet any of those boxes records no scroll. With no float in the layer and none in either frame, none of this runs: two length tests per frame.

Alternative: forget the covered segments every frame; rejected, it repaints 17 rows of 200 cells per key while a float is open.

### Esc and the action

`float.close` is a `FloatHandler` over `CloseFloat`, which closes the topmost float of the current tab page and does nothing when none is open; `<Esc>` in normal mode is bound to it in `config/default.caratrc`, so a plugin or user binding can replace it.

### Plugin requests (API 2.3)

`PluginApi::FloatOptions` is a `Data` value with the spec's fields plus `enter`; `FLOAT_ANCHORS` lists the anchors. `open_float(options, lines)` validates the anchor, a size of at least 1 by 1, and a z from 0 to 1000, copies the lines and the title, opens a scratch buffer owned by the plugin (outside the buffer list) in a float through `OpenFloat`, and answers its window id; a full layer fails. `move_float(window, row, col)` and `close_float(window)` find the float in any tab page and fail for an unknown id or another plugin's float. They live in `WindowRequests` beside the other window requests, each with its `PluginLink` override; `MINOR` becomes 3.

## Risks / Trade-offs

- [A float's buffer is outside the buffer list, so `:ls` and `:b` do not see it] → intended: it is a view a plugin owns; `:w` in it fails as in any scratch buffer.
- [A disabled plugin's floats stay open] → Esc closes them; the backlog keeps closing them on disable.
- [Chrome comparison of covered rows costs a row compare per covered row] → measured by `lh-float` against the 20 microsecond budget.
- [A screen too small for a float's border] → the float is not painted while its box does not fit.
