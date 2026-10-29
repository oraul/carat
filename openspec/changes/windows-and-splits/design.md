# Design

## Context

See proposal.md for motivation. Today `EditorState` holds one `Buffer`, one `Window` (scroll offsets and the height of the last render), and one `Cursor`; `OpenFile` replaces all three through `state.load`; `Quit` sets the quit flag; `ExecuteEx` loops over "every buffer" with one iteration; `FramePresenter` paints one gutter, one text area, one status line, and the message row; `Motions.screen` reads `state.window.top` and `height` for `H M L`. The command grammar completes any action outside the `cursor.`, `motion.`, `operator.`, `textobject.`, and `register.` namespaces at once with the count typed before it, so `window.*` and `tab.*` actions need no grammar change. `docs/architecture.md` section 4 names `Window`, `Layout`, and `TabPage` as entities and section 5.3 names `SplitWindow`, `CloseWindow`, `FocusWindow`, `ResizeLayout`, and `OpenTab` as use cases.

The Spinel facts recorded by the earlier designs shape the representation: inline RBS pins `Array[T]` only with a builtin `T`, so an array of program objects is `Array[untyped]` to the compiler; an element read from such an array is `untyped` and a `Data` value read that way cannot be dispatched to, while a `Struct` value can, and a method with a return signature re-types what it returns (this is how `Frame#cell` serves `Cell` out of `Array[Array[Cell]]`); a local that holds two types widens a method for the whole program; a nullable local stays nullable after a nil check; block-form `Data.define` and `Struct.new` ignore inline RBS; an empty array literal is `Array[Integer]` unless stored through a writer after `super()`. One more fact was established with a probe program against the pinned compiler while implementing this change: an empty array literal held in a local and passed to another method is copied, so the callee's pushes are lost (a seeded array, or one the callee returns and the caller assigns, keeps them); `Layout#leaves` therefore builds its list on the way back up the tree with `concat` rather than filling one passed down.

## Goals / Non-Goals

**Goals:**

- Every existing use case keeps working unchanged through `state.buffer`, `state.cursor`, and `state.window`, which now resolve through the current tab page's current window.
- The layout tree is a plain domain record that the presenter, the use cases, and the tests drive with the same calls: split, close, neighbour, equalize, arrange.
- `make types` shows no new `untyped` member on `Window`, `Layout`, `TabPage`, or `EditorState`, and `make diagnose` stays clean.
- The explorer change can mark a window fixed-width and have the editor leave it alone on resize and equalize.

**Non-Goals:**

- The buffer list commands and buffer numbers that survive deletion; `E141` uses the list position.
- Per-window local options; `Options` stays global.
- Scroll synchronization, window resizing commands, and any `splitbelow`/`splitright` behavior.

## Decisions

### The layout is a flat node table with integer ids

`Layout < Struct.new(:nodes, :root)` holds every node of the tree in one array; `LayoutNode < Struct.new(:kind, :parent, :children, :window, :size)` is a `Struct` record whose `kind` is `:leaf`, `:column` (children stacked, made by `:split`), `:row` (children side by side, made by `:vsplit`), or `:free` (a slot a closed node left, reused by the next allocation); `parent` and `children` are node ids, `window` is the `Window` of a leaf (nil for an inner node), and `size` is the node's extent along its parent's axis: total rows including the status line under a `:column`, columns without the separator under a `:row`. `Layout#node(id) -> LayoutNode` and `Layout#window_at(id) -> Window` are the only reads of the array, so their return signatures re-type what `Array[untyped]` lost, exactly as `Frame#cell` does. The alternative, a recursive tree of `Struct` nodes holding their children, needs the children pinned `Array[untyped]` and every walk to re-type each child; the flat table keeps the walks over `Array[Integer]` and makes window numbering (`<C-w>w` with a count), previous-window tracking (`<C-w>p` remembers an id and checks it is still a leaf), and the tests trivial. Node ids are what `TabPage#current` and `TabPage#previous` hold. The names `:column` and `:row` follow Vim's `FR_COL` and `FR_ROW`.

### Windows carry their buffer, cursor, scroll, and rectangle

`Window < Struct.new(:buffer, :cursor, :top, :left, :row, :col, :height, :width, :fixed_width)`: `top`, `left`, and `height` keep their meaning (text rows; 0 before the first render, in which case the screen motions treat the whole buffer as visible, as today), `row`, `col`, and `width` are the rectangle `Layout#arrange` assigned at the last render, and `fixed_width` is Neovim's `winfixwidth`. A window is a `Struct` because it is mutable and because `Struct` values survive dynamic dispatch. `Window#show(buffer)` replaces the buffer and resets the cursor and the scroll; `Window#copy_from(other)` is what a split uses to give the new window the same view. `Window#gutter_width(options)` moves from the presenter to the window, since the minimum width of a split depends on it.

### Geometry is computed by the layout, once per render

`Layout#arrange(row, col, height, width)` walks the tree from the root, assigning each leaf window its rectangle and fitting the children of each inner node to the parent's extent: a `:column` node's children sizes must sum to its height, a `:row` node's to its width minus one separator per gap. When they do not, because the terminal changed, the last child absorbs the difference down to its minimum (two rows for a leaf under a column, one column under a row), then the one before it, skipping fixed-width windows under a `:row` node while another child can change; this is Neovim's `frame_new_height` and `frame_new_width` order. The presenter then paints each leaf at its rectangle, draws a status line at `row + height`, and a separator column at `col + width` for every `:row` child but the last. Keeping geometry in the layout rather than the presenter lets `Layout#neighbour` and the domain tests reason about rectangles without a frame.

`Layout#split(id, vertical, size, min_width)` returns the new leaf's id or -1 for `E36`: a horizontal split needs the current window to have at least three text rows (one for the new window, one for the old, one status line between), a vertical one needs `2 * min_width + 1` columns where `min_width` is the current window's gutter plus one. Without a size the new window gets `h / 2` text rows or `w / 2` columns and the old one the rest minus the status line or the separator, matching Neovim's `win_split_ins` with `splitbelow` and `splitright` off; a size is clamped so the old window keeps its minimum. When the current leaf's parent already has the split's orientation the new leaf is inserted before it; otherwise the leaf is replaced by a new inner node of that orientation holding the new leaf and the old one, which takes over the old leaf's size.

`Layout#close(id)` removes a leaf, gives its size to the sibling after it, or before it when it was last, preferring a non-fixed sibling when the chosen one is fixed-width and the other is not (Neovim's `win_altframe`), and collapses a parent left with one child by moving the child into the parent's place. `Layout#neighbour(id, direction, cursor_row, cursor_col)` scans the leaves for the rectangle adjacent to the current one's edge (the column after its separator, the row after its status line) that overlaps the given screen row or column; adjacency in a tiling layout means the edges coincide, so no tree walk is needed. `Layout#equalize` recurses from the root, giving each child of a column `height / n` rows with the remainder to the first children, and each non-fixed child of a row an equal share of the width left by the fixed ones.

### Tab pages and the state

`TabPage < Struct.new(:layout, :current, :previous)`; `EditorState` replaces its `buffer`, `window`, and `cursor` members with `buffers` (`Array[untyped]` read through `buffer_at(i) -> Buffer`), `tabs` (read through `tab_at(i) -> TabPage`), and `tab_index`, and defines `tab`, `window`, `buffer`, and `cursor` as methods with return signatures, so every use case and test that reads `state.cursor` or sets `state.window.height` is unchanged. `EditorState.new(buffer, options, timeoutlen)` keeps its signature and builds one tab page with one window. The state owns the buffer list rules: `load(buffer)` adds the buffer to the list if absent, shows it in the current window, and drops the buffer the window showed when no window in any tab page shows it any more (the callers guarantee it is unmodified or that a bang discarded it); `release(buffer)`, called when a window closes, drops it only when it is unmodified and unshown, which is what keeps a modified buffer hidden; `buffer_for(path)` finds a listed buffer by path; `modified_buffer` finds the first modified one for `:qa` and `:q!`. Identity is checked with `equal?`, never `==`, because two `[No Name]` buffers are equal by value. Tab navigation (`switch_tab`, `add_tab`, `close_tab`) lives on the state too, since the tab list is its member; counts are applied there so `3gt` and `:tabn` share one method.

### Use cases per command family

`SplitWindow#call(state, vertical, size, path, fresh)` splits through the layout, copies the view or opens the file with `OpenFile` or shows a fresh empty buffer, and returns `E36` as an `Outcome`; `CloseWindow#close(state, n)` and `#only(state)` close windows and tab pages and release buffers, reporting `E444` and "Already only one window"; `FocusWindow` moves in a direction, cycles, or returns to the previous window; `ResizeLayout#equalize`; `OpenTab#call(state, path)`, `CloseTab#close` and `#only`, `SwitchTab#next(state, n)`, `#previous(state, n)`, `#first`, `#last`. `Quit#call(state, bang)` becomes the `:q` rule: close the window through `CloseWindow` when another window exists anywhere, otherwise end the editor unless a listed buffer is modified (or, with the bang, show the first modified hidden buffer instead of ending); `Quit#all(state, bang)` is `:qa`. `ExecuteEx` gains one arm per ex command and receives the new use cases through its constructor; `write_all` loops over the buffer list with `SaveFile#write(buffer, path_arg)`, a new entry point that `SaveFile#call` delegates to. `Dispatcher` routes `window.*` and `tab.*` to these use cases with the command's count, and `window.quit` through `Quit` with the outcome shown as the command line shows it. The alternative of one `ManageWindows` use case was rejected because the architecture names the smaller ones and each has one job.

### Rendering

`FramePresenter#call` reserves row 0 for the tab line when the state has more than one tab page, the last row for the message, and hands the rest to `Layout#arrange`; it then paints every leaf: gutter and text inside the rectangle with the existing `paint_line` taking a column offset, `~` rows, the status line in `STATUS` for the current window and `STATUS_NC` for the others, and the separator column in `STATUS` with the vertical bar U+2502; the cursor is placed in the current window. Each window scrolls to its own cursor before painting. The tab line is painted from the tab pages with `TAB_LINE`, `TAB_LINE_SELECTED`, and `TAB_LINE_FILL`, which `ScreenPresenter#sgr` maps to reverse video, bold, and reverse video, with `STATUS_NC` as dim reverse video. The frame itself is unchanged.

### Bindings and docs

`config/default.json` binds `<C-w>s v h j k l w W p c o = q` to `window.*` actions and `gt`, `gT` to `tab.next` and `tab.previous` in the `normal` map; `docs/actions.md` lists them as plain actions that take a count. The ex registry accepts the shortest and the full spelling of each command, as it does today.

### The harness draws after every key

`EditorHarness#type` renders after each key rather than once at the end, because `MainLoop` draws after every read and a window command reads the rectangles the previous key's render arranged: `<C-w>s<C-w>j` typed in one call must find the new window below.

### Tests

`test/domain_layout.rb` drives `Layout` and `EditorState` directly: split sizes with and without a count, `E36`, close and the space it gives back, neighbour lookup in both orientations, equalize with and without a fixed-width window, arrange after a resize, window numbering, and tab navigation with counts. `test/editor_windows.rb` and `test/editor_tabs.rb` are table-driven over the harness, which gains `window_count`, `tab_count`, `tab_index`, `window_index`, and `windows` (each window's rectangle and buffer path) helpers; every binding and ex command of the specs has a row. `test/adapters_frame_presenter.rb` asserts two-window frames in both orientations and a two-tab frame; `test/smoke_editor.rb` types `:vsplit`, `:tabnew`, and the quits in the pseudo-terminal.

## Risks / Trade-offs

- [`Array[untyped]` for the nodes and the buffers] → every read goes through one method with a return signature, as `Frame#cell` does, and `make types` on `main` is diffed against the branch for new `untyped` members before the change is committed.
- [Nullable `window` on a leaf node] → read only through `Layout#window_at`, whose return signature is `Window`; inner nodes never reach it.
- [Buffer identity by value] → every list lookup uses `equal?`; `test/domain_layout.rb` covers two unnamed buffers in the list.
- [Neovim's exact split sizes and resize distribution] → the chosen rules are stated in the specs and the compatibility note; anything not stated is not claimed.
- [`make snapshots` rewrites every `.expected`] → the diff is reviewed; only the new and extended test programs gain lines.
- [A wide `Dispatcher` and `ExecuteEx` constructor] → the assembly and the ex use case test are the only constructors; each new use case is one line there.
