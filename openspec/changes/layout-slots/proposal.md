# Proposal

## Why

A plugin's side window is today a fixed-width window added at the edge of the tab page wherever and as wide as the plugin asks, with nothing to show what it is, no way to put it away and bring it back without losing its place, and no bottom area at all. The approved UI plan gives every tab page an IDE layout: a left and a right sidebar and a bottom panel at fixed places, sized by configuration, each with a header naming the views it holds, and keys that hide and show them. The user put the remaining UI first; this is its first item, split from the breadcrumbs, which are the next queue item.

## What Changes

- Each tab page gets three slots: the left sidebar, the right sidebar, and the bottom panel. A plugin's scratch window opens in the slot its side names (`left`, `right`, or the new `bottom`); the panel spans the width between the sidebars and keeps its height when windows are equalized, as a sidebar keeps its width.
- A slot shows one view at a time in one window. Opening another plugin's scratch buffer in a slot that already has a window shows it in that window instead of adding a window; the view shown before is let go and comes back when its plugin opens it again.
- Each slot window has a header row at its top listing the titles of the views opened in the slot, the shown one highlighted as a selected tab; its text starts on the row below.
- Configuration sizes the slots: `option.layout.left_width`, `option.layout.right_width`, and `option.layout.panel_height`, numbers from 0 to 500; 0 (the default) keeps the size the view asks for, as the explorer's `plugin.explorer.width`, and a positive value fixes the slot's size for every view.
- New actions `layout.toggle_sidebar`, `layout.toggle_right_sidebar`, and `layout.toggle_panel` hide a shown slot (its window leaves the layout, kept with its cursor) and show a hidden one again where it was, bound to `<leader>ls`, `<leader>lr`, and `<leader>lp` under a new `<leader>l` layout group; an empty slot answers "No view in the left sidebar" (or right sidebar, panel); hiding the only window answers E444.
- The explorer opens in the left slot (its `plugin.explorer.side` picks the right slot instead), so it gains the header and the toggle.
- The plugin API goes to 2.4 for the `bottom` side.
- Rows in `docs/actions.md` and `docs/compatibility.md` for each slot, option, and action.

Out of scope: the breadcrumbs (queue item 2, `breadcrumbs`); choosing a view from the header with a key or the mouse; moving a view between slots at run time; resizing a slot with keys; a core view (terminal, diagnostics list) for the panel.

This change is not a numbered item of `docs/architecture.md` section 12: it is a UI item of the T5 roadmap track in `docs/goals.md`, ordered by the user.

Assumptions: the brief names `layout.toggle_sidebar` and `layout.toggle_panel`; the first toggles the left sidebar and a third action, `layout.toggle_right_sidebar`, gives the right sidebar the same key, since a slot no key can bring back would be lost once hidden. The leader group is `<leader>l`, named layout. The sizes are `option.layout.*` lines, since every option line has the `option` scope, as `option.keyhints.delay` does; their default of 0 keeps every existing plugin's requested size, so nothing changes for a user who sets none. Toggling a slot on does not move the focus, as an IDE's sidebar toggle does not.

## Capabilities

### New Capabilities

- `layout-slots`: the per-tab-page sidebar and panel slots, their headers, their size options, and their toggle actions.

### Modified Capabilities

- `plugin-windows`: a scratch window opens in a slot, at the left, the right, or the bottom, sized by the slot's option when set, and shares the slot's one window with the slot's other views.

## Impact

- Domain: new `Slot`; `TabPage` holds three; `Window` gains `fixed_height`; `Layout` gains `split_bottom` and `place_slot` and keeps a fixed-height window's height as it keeps a fixed width; `TabList#shown?` counts a hidden slot's window; `BufferList#close_tab` lets go of it; `Options` gains the three sizes.
- Use cases: `OpenSideWindow` places into the slot; new `ToggleSlot` and `LayoutHandler`; `ArrangeView` reserves the header rows; `WindowRequests` accepts `bottom`.
- Adapters: `FramePresenter` paints the headers; `EditorAssembly` wires the handler.
- Plugins: `PluginApi::SIDES` gains `bottom`, version 2.4.
- Configuration: `config/default.caratrc` (three options, the group, three bindings) and its generated mirror.
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, `docs/architecture.md`, `docs/codebase-map.md`, `README.md`.
