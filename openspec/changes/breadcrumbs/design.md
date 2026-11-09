# Design

## Context

Since `layout-slots` (#80) `ArrangeView` lays out the tab page with `Layout#arrange` and then moves each shown slot window one row down and one row shorter for its header (`reserve_headers`), which `FramePresenter#paint_headers` paints as chrome, compared cell by cell. The language-server gateway (`JsonRpcLanguageGateway`) works only on idle ticks (`InputController#pump` calls `poll` when a read returns nothing, every 0.25 s or 0.02 s while it waits), keeps one shared ask record per feature (`HoverRequest`, `SignatureRequest`, `CompletionRequest`) matched to the request in flight by `sent_id`, and stores from `initialize` only the capabilities it uses. No file-window count exists: `TabPage#window_count` counts every leaf and `BufferList#file_count` counts buffers.

## Goals / Non-Goals

Goals: a winbar per file window with the path and the cursor's symbol path, shown by default only with two or more file windows; a symbol answer that is slow or stale never delays a key; no allocation per key more than today when no winbar shows (`lh` 27.0, `j` 28.0); the layout-rectangle neighbour rule recorded.

Non-goals: symbol navigation, `:set breadcrumbs`, kinds or icons, symbols for buffers other than the current window's, winbars on scratch windows.

## Decisions

### The winbar is a reserved row, like a slot header

`ArrangeView#call` calls `reserve_winbars` after `reserve_headers` when `TabPage#winbar?(options.breadcrumbs)`: each leaf window whose buffer is not scratch and has two rows or more starts a row lower, a row shorter. The layout tree, its node rectangles, and so the separators and `Layout#neighbour` are untouched; scrolling, `H`, `M`, `L`, and cursor clamping read `Window#height`, so they see the text rows. `FramePresenter#paint_winbars` paints the row above each such window when it is its node's top row (the same test `paint_headers` uses), adds it to the chrome rows, and marks it repainted under floats. The window rectangles are in the frame's layout key, so a winbar appearing or going repaints the window rows once. Alternative: a winbar inside `Layout#arrange` as part of the leaf's extent; rejected, since the layout tree's minimum sizes and `E36` checks would change for every split.

### A split counts the rows of its leaf

`Layout#split` read the window's height, which `ArrangeView` had already shortened by a header or winbar row, so a half split of a window with a winbar came out one row short and splits typed before a frame disagreed with those after one. It now counts the leaf's rectangle less its separator row, the same figure for a window with and without a reserved row, and `SplitWindow` adds the winbar's row to a count when the windows will show winbars once the split is made, so `5<C-w>s` still gives the new window five text rows, as `:resize` and a split count measure text rows in Neovim. Without winbars the rectangle less its separator is the window's height, so nothing changes there.

### Shown when, counted how

`TabPage#file_window_count` walks the node table (`node_count`, `leaf?`) counting leaves whose window's buffer is not scratch, building no list, so it allocates nothing; `winbar?(mode)` is false for `never`, true for `always`, and `file_window_count > 1` for `auto`. Slot windows and plugin windows hold scratch buffers, so the explorer beside one file shows no winbar. `option.breadcrumbs` is a string option checked against `Options::BREADCRUMBS`; it is read from configuration lines only, as `option.layout.*` are.

### The painter reads the state and allocates nothing

`Adapters::Winbar#paint(frame, window, row, current)` blanks the row in `TabLineFill`, then writes one space, `Buffer#display_name` (or `[No Name]`), and, when the shared `SymbolRequest` holds that buffer's symbols, ` > ` and each held name whose range holds the cursor row, in the stored order, each with `Frame#put_within` to the window's right edge, which replaces control characters and stops at the limit. Every string it writes is already stored, so a frame with winbars allocates nothing more either. The groups are the header's: `TabLineSel` for the current window, `TabLine` for the others.

### Symbols are one shared ask, sent at idle ticks

`Domain::SymbolRequest` (a `Struct`, built in `EditorAssembly` and shared by the gateway and the painter) holds the languages whose server offers `documentSymbolProvider`, the text last asked (buffer id, `Buffer#changes`, `Buffer#closed_count`), the request in flight (`sent_id`, `language`, `deadline`), and the answer: the buffer id it is for and parallel arrays of names, start rows, and end rows. `JsonRpcLanguageGateway#send_symbols` runs in `poll` after the document sync, so `didOpen` or `didChange` precedes the request: with a request in flight it only cancels it past `ANSWER_LIMIT` (`$/cancelRequest`, `sent_id` 0, so a late answer is dropped by `receive`); otherwise, when a winbar shows and the current layout window's buffer's text differs from the text last asked and its running server offers symbols, it sends `textDocument/documentSymbol`. `waiting?` includes a request in flight, so the controller polls every 0.02 s until the answer. A text changed while a request is in flight is asked after the answer, at the next idle tick, so at most one request is in flight and typing sends at most one per round trip; nothing runs on the key path. A crash forgets the server's language and its request.

### The answer is read at the boundary

`Adapters::SymbolOutline.read(result, symbols)` clears the held symbols and records the asked buffer as their owner, then walks a `DocumentSymbol[]` (`range`, `children`) or `SymbolInformation[]` (`location.range`) list in order, parents before children, keeping at most `LIMIT` (500) symbols, `DEPTH_LIMIT` (8) levels, each name stripped of control characters by `ControlText.strip` and cut to `NAME_LIMIT` (40); an item without a string name or a valid range (start line 0 or more, end not before start) is skipped, its children still read. The symbol path at a row is every held symbol whose start and end rows hold it, in stored order, which for a hierarchical answer is outermost first. An error answer or a result that is not a list holds no symbols for the buffer.

### The neighbour rule is recorded, not changed

`Layout#neighbour` already picks the leaf whose node rectangle abuts the window's and overlaps the cursor's screen row or column. The `windows` spec gains a nested-split scenario, the `docs/compatibility.md` row and its note say rectangles, `test/domain_layout.rb` names the rule in its check labels, and `test/editor_windows.rb` adds the nested case through keys.

## Risks / Trade-offs

- Every existing test with two file windows now has winbars: its rectangles and frames move down a row. The new rows are reviewed in the snapshot diff; `option.breadcrumbs never` restores the old layout for a user who wants it.
- A server's hostile answer is bounded: 500 symbols, 8 levels, 40-byte names without controls; the JSON itself is already bounded by `RpcFramer`'s 8 MiB body limit.
- With winbars shown and an answer kept for an older text, the path may name the symbol the cursor was in before an edit until the next answer, at most one round trip later.

## Tests

- `test/editor_breadcrumbs.rb`: `file_window_count` and `winbar?` per mode, winbar rows per case (one window, two, closed back to one, explorer beside one, `always`, `never`, a one-row window), the path and the symbol path through the gateway with a fake server, no request without the capability or with no winbar, a key handled before a slow answer, a cancelled answer dropped, an overdue request cancelled, names cleaned and capped.
- `test/domain_options_config.rb`: the option's values and its problem line.
- `test/editor_windows.rb` and `test/domain_layout.rb`: the rectangle-rule rows.
- `make bench` on `lh` and `j`: allocations per key unchanged. A new `lh-winbar` scenario (two windows, winbars shown) allocates as many objects per key as the same two windows with `never` (31.0 each), so painting the winbars allocates nothing.
