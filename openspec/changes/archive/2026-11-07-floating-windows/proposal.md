# Proposal

## Why

No window can float over the layout, and the completion list, the documentation popups, parameter info, and peek definition all need one (docs/queue.md item 1, goal 1). This delivers the floating windows step of the UI track in `docs/architecture.md` section 12, which section 9 already names as "floating windows later" for plugins.

## What Changes

- A float spec value: an anchor (the editor's top-left corner or the cursor cell), a row and column offset, a size in text rows and columns, a border with an optional title, and a z order.
- A float layer per tab page holding its floats by z, at most 16, a float with the higher z painted over the lower and a float opened later over an earlier one of the same z.
- Focus into a float (opened with enter, or a plugin focusing its id) and out of it: a Ctrl-W focus command in a float returns to the window that was current under it, focusing any window of the layout leaves the float, and `:q`, `:close`, and Ctrl-W c in a float close the float only.
- Painting by z after the windows and the status bar, in `NormalFloat` with a rounded `FloatBorder` border and the title in `Title`; the rows a float covers or covered are compared cell by cell, the window rows under it are repainted only when its rectangle changes, and no scroll region is sent for a window a float covers or covered.
- Esc in normal mode closes the topmost float of the tab page, through the new action `float.close`.
- Plugin host requests `open_float`, `move_float`, and `close_float`, a plugin moving and closing only its own floats; the plugin API goes from 2.2 to 2.3.
- A bench scenario `lh-float` with a 60 by 15 float open.

## Capabilities

### New Capabilities

- `floating-windows`: windows that float over a tab page's layout: their spec, placement, z order, focus, painting, and closing.

### Modified Capabilities

- `plugin-windows`: a plugin opens, moves, and closes floats.

## Impact

- Domain: new `FloatSpec`, `FloatWindow`, `FloatLayer`; `TabPage` gains the layer and its `window` answers the focused float; `Frame` gains the float key; `TabList#float_tab`.
- Use cases: new `OpenFloat`, `CloseFloat`, `FloatHandler`; `ArrangeView` places floats; `FocusWindow`, `CloseWindow`, `Quit`, and `SplitWindow` treat a focused float; `WindowRequests` and `PluginLink` gain the three requests.
- Adapters: `FramePresenter` paints floats; `PaintedRows#forget`; `Frame#same_cells?`; `EditorAssembly` wiring.
- Plugin API 2.3 (`PluginApi::FloatOptions`, three `Host` methods); `config/default.caratrc` binds `<Esc>` in normal mode.
- Docs: `docs/actions.md`, `docs/plugins.md`, `docs/codebase-map.md`, `docs/architecture.md` section 9.

Out of scope: the completion list and documentation popups themselves, a float relative to a window other than the cursor's, resizing a float from a plugin, mouse interaction, scrollbars, cycling into a float with Ctrl-W w, and closing a plugin's floats when it is disabled.

Assumptions: the acceptance figure "lh under 20 microseconds with a 60 by 15 float" is measured by `make bench` as `lh-float`, total time per key; a float's buffer is the plugin's scratch buffer, kept out of the buffer list and dropped with the float.
