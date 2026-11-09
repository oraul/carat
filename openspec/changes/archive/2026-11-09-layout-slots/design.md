# Design

## Context

A tab page (`Domain::TabPage`) holds a layout tree (`Domain::Layout`, a flat table of `LayoutNode`s), its current leaf, the previous one, and its floats. A plugin's scratch window is a layout leaf added by `OpenSideWindow` through `Layout#split_edge` at the root row's left or right end, its `Window#fixed_width` set so `equalize` and `fit` leave its width alone. Every walk over windows (focus, `Ctrl-W`, close, the plugin requests, painting) goes through the layout's leaves, and the scratch buffer is let go (`BufferList#release`) when no window shows it.

## Goals / Non-Goals

Goals: three slots per tab page at fixed places, sized by configuration, a header row listing each slot's views, keys that hide and show a slot keeping its view, the explorer in the left slot, no change for a user who sets nothing but the header row.

Non-goals: the breadcrumbs (next queue item); a slot outside the layout tree; picking a view from the header; key resizing.

## Decisions

### A slot's window stays a layout leaf

The slots could live outside the tree, the arrange carving their columns first, but then focus, `Ctrl-W` moves, close, the plugin window requests, painting, and the highlighter would each need a second kind of window. Keeping a shown slot's window a leaf at the tree's edge keeps every one of those paths as it is. `Domain::Slot` (a `Struct`: `side`, `views`, `window`, `hidden`, `size`) records which window is the slot's, the titles it lists, and its size; `TabPage` holds `left_slot`, `right_slot`, and `panel_slot`, reached by `slot(side)` and `slot_at(index)`.

A slot is shown while its window is a leaf of the layout, not hidden, and still shows a scratch buffer: a file opened in the slot window (the explorer's open with no editing window) or a close of the window by any path ends the slot without a hook in each close path, and the next view opens a new slot window.

### Hiding takes the leaf out and keeps the window

`ToggleSlot` hides a shown slot by `Layout#close` of its leaf, keeping the `Window` (its id, cursor, and scroll) in the slot with the size the leaf had, and moves the focus as `BufferList#close_window` does; it shows a hidden slot by placing the same window again (`Layout#place_slot`). `TabList#shown?` counts a hidden slot's window, so `release` keeps its scratch buffer, and the plugin's next open of that title finds the buffer and reaches the slot, which shows again. `BufferList#close_tab` lets go of a hidden slot's buffer with the page. A hidden window whose buffer left the list (its plugin was disabled) empties the slot when shown.

### Placement: sidebars at the root row's ends, the panel between them

`Layout#split_edge` keeps placing a sidebar at the root's left or right end. `Layout#split_bottom` places the panel under the content between the sidebars: when the root is a row whose first or last child is a fixed-width leaf, the panel goes under the children between them, grouped into a new row when there are several; otherwise under the root. A sidebar added later wraps the column holding the panel, so the panel stays between the sidebars either way. Both go through one private `attach`, which wraps a node in a new split of a kind or joins a split of that kind.

### Fixed height mirrors fixed width

`Window#fixed_height` marks the panel. `Layout#fixed_width?` becomes the axis-general `fixed?(id, along_row)` used by `equalize_node` (which now shares one branch for rows and columns), `fit`, and `close`; `fixed_width?` stays as its row case. A plugin window that takes a file loses both flags (`Window#unfix_size`).

### Sizes from configuration

`Options` gains `layout_left_width`, `layout_right_width`, and `layout_panel_height` from `option.layout.left_width`, `option.layout.right_width`, and `option.layout.panel_height`, 0 to 500, through one bounded-number helper. A positive value is the slot's size whatever the view asks; 0 keeps the view's (the explorer's 30). The size is read when the slot window is first placed; a hidden slot comes back at the size it had.

### One window per slot, views listed in the header

Opening a scratch buffer in a slot with a window shows the buffer in that window (`Window#show`), lets go of the one shown before, and adds the title to the slot's views; the header lists every title opened in the slot since its window was placed, the shown one in `TabLineSel`, the others in `TabLine`, the rest of the row `TabLineFill`. `ArrangeView` moves each shown slot window one row down and one row shorter after `Layout#arrange`, so the layout tree and its separators are untouched; `FramePresenter` paints the header rows as chrome, writing the titles the buffers hold, so a frame allocates nothing more.

### Actions

`LayoutHandler` registers `layout.toggle_sidebar`, `layout.toggle_right_sidebar`, and `layout.toggle_panel`, each a variant calling `ToggleSlot`, bound in normal mode under `<leader>l`.

### Plugin API 2.4

`PluginApi::SIDES` gains `bottom`; the `width` argument of `open_scratch` is the panel's height for it. A plugin built for 2.3 keeps working (the host accepts an older minor).

## Risks / Trade-offs

- The header takes one row from every slot window: the explorer shows one tree row fewer. Its snapshots move by a row.
- A view let go when another takes its slot loses its cursor; its plugin rebuilds it on the next open, as it already does for a closed window.
- `lh-explorer` and `j-explorer` paint the header row each frame; it allocates nothing, which the benchmark checks.
