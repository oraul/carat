# Proposal

## Why

The user's photos of 2026-11-23 show four edges that `docs/design.md` does not draw: a `│` after every buffer tab, the tab row painted from column 0 over the sidebar instead of from the editor's first column, a separate sapphire `explorer` row heading the sidebar, and `~` rows under the explorer's tree. The design says tabs are told apart by background and surfaces meet by background, the sidebar head reads the project and branch, and a tab row heads the explorer's column. The dashed line at the sidebar's edge is the terminal's padding seam, outside carat's grid, and no carat fix is proven.

## What Changes

- Remove the tab separator: `TabBar::SEPARATOR` and `ASCII_SEPARATOR` and the write after each tab go, and `FRAME_CELLS` drops from 6 to 5.
- Start the tab row at the editor's first column: `TabBar#paint` takes a start column, the left sidebar's `col + width + 1` (0 with none shown), and fills, writes, counts, and places the tab-page numbers from it.
- Add `TabBar#paint_head`: the project (last segment of `BufferList#base`) in `Normal`, a dot (`·`, `-` under ascii) in `NonText`, and the branch (`StatusSlots#branch`) in `MsgDim`, on the sidebar layer, painted by the frame presenter over the left sidebar's width on the tab row.
- Give the left sidebar a header row only while it holds two views or no tab row shows (`Slot#headed?`, read by `ArrangeView` and the presenter); with one view and no tab row its first row reads the head in place of the view's title; with one view and a tab row the tab row carries the head and the tree starts on the row under it.
- Draw the rows of a sidebar window below its text blank (`PaintedRows::BLANK`) instead of `~`; editor windows keep their tildes.
- Update the tests and snapshots these change, and add the frame test at 80 columns with a sidebar and two tabs at 24 bits, 16 colors, and NO_COLOR.

Out of scope: the tab row's colors and the active tab's fill (`one-accent`), the active tab staying marked while the explorer has focus (`tab-focus-mark`), the design-drift table and `docs/design.md` (`design-drift-sync`), the explorer's own `carat` root row, the right sidebar and the panel (they keep their header rows), and the terminal's dashed edge.

Assumptions: the head's groups reuse `Normal` (bright), `NonText` (faint), and `MsgDim` (dim) lifted onto the sidebar layer, since `one-accent` adds the bold no-fill group later and a new group would shift every group id; the head reads the sidebar's first row when no tab row shows, so the sidebar keeps a head with a single open file, the common state; "the slot holds two views" is applied to the left sidebar only, the right sidebar and the panel keeping their titles; the spacing between neighbouring tabs is the three cells the removed separator leaves (a trailing space and the next tab's two leading spaces), the council's two-cell gap and the icon's removal belonging to `one-accent`; with no working directory known the head shows the branch alone.

## Capabilities

### New Capabilities

### Modified Capabilities
- `buffer-tabs`: no separator, the row starting at the editor's first column, the sidebar's head on it.
- `layout-slots`: the left sidebar's header row only with two views or no tab row, the head in place of a title.
- `screen-rendering`: blank rows, not `~`, below a sidebar's text.

## Impact

- Code: `carat/adapters/tab_bar.rb`, `carat/adapters/frame_presenter.rb`, `carat/adapters/painted_rows.rb`, `carat/domain/slot.rb`, `carat/use_cases/arrange_view.rb`.
- Tests: `test/adapters_tab_bar.rb`, `test/adapters_frame_presenter.rb`, `test/domain_slot.rb`, `test/editor_slots.rb`, `test/editor_plugins.rb`, `test/editor_explorer.rb`, `test/editor_tabs.rb`, `test/editor_tab_flows.rb` and their snapshots.
- Docs: README.md (the slots paragraph), `docs/compatibility.md` (the buffer tabs row and the layout slots paragraph), `docs/codebase-map.md` (slot, arrange view, frame presenter, tab bar, painted rows).
- docs/architecture.md: unchanged, it names the tab bar, slot header, and presenter as parts and describes no separator, head, or tilde row.
- docs/design.md: unchanged, it already describes the target look; its drift table is `design-drift-sync`'s.
