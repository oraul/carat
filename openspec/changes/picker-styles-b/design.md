# Design

## Context

A plugin float is a `Domain::FloatWindow` over a plain `Domain::Buffer` the plugin owns, outside the buffer list, built by `WindowRequests#open_float`. The editor already draws two kinds of float style: `FloatWindow#selected`, a menu's selected row (`FramePresenter#float_group`: `PmenuSel` on that row, `Pmenu` on the others, `NormalFloat` when -1), and `Buffer#styles`, one `SyntaxLine` per row kept for that row's very string, whose tokens `paint_float_row` paints on the float layer. The palette (`FollowPalette#show`) uses both. No plugin request reaches either, and the presenter's float key holds the buffer's change counters and `selected` but nothing that moves when only the styles change.

## Decisions

### One request for the row and the spans

`style_float(window, selected, spans)` sets both at once and replaces whatever style the float had, so a plugin restyles after each refill with one call and clears with `(id, -1, [])`. Spans are flat integer quadruples (row, start column, length, group id), the tokenizer's triples with a row in front, so a plugin reuses its token code and the request stays one integer array across a future JSON-RPC link. No `FloatOptions` member is added. The request belongs to the window family: `Host#style_float`, `PluginLink#style_float` (refusal check, then forward), and `WindowRequests#style_float(name, id, selected, spans)`.

### Which groups

`Highlight.float_style?(id)` admits what `token?` admits plus `POPUP_MENU_SELECTED` and `POPUP_MENU_MATCH`; every other UI group stays refused. `token?` is unchanged, so a tokenizer cannot paint UI groups into a file. `Highlight.float_style_id(name)` resolves a token group's name or `PmenuSel` or `PmenuMatch`, and `UiRequests#syntax_group` uses it, so a plugin gets the two ids the way it gets a syntax group's; a tokenizer token in either is dropped by `PluginSyntax#copied_tokens` as before. On the selected row the host draws `PmenuMatch` spans in `PmenuMatchSel`, as the palette does, so a plugin need not know which row its match spans fall on.

### Validation before change

The request resolves the float as `set_float_lines` does (`own_float_tab`, then the listed-buffer check, "No float N"), then checks `selected` (-1 or a row of the float's buffer), the span list's length, and each span's row, column, length, and group, and only then writes, so a refused request leaves the previous style. A span past the line's end is cut by the painter, as a token is.

### Storing the style

Each row gets a `SyntaxLine` built with the buffer's own line string, so `Buffer#style_at` draws it only while that string is still the row's; `float.selected` takes the selected row. A span's length is kept cut to 2^30 (`LONGEST_SPAN`), more than any line holds, so the painter's column plus length never grows past what it can add; the cut draws the same cells. With no span at all the buffer's styles are emptied, so `styled?` is false and the painter skips the token pass. `set_float_lines` also empties the styles and sets `selected` to -1, since a refill's rows are new strings and a selected row would point at a different entry.

### Repainting a restyle

`FloatWindow` gains `style_count`, raised by every accepted `style_float`; `FramePresenter#build_float_key` appends it, so `FLOAT_STRIDE` becomes 11 and each notification box appends one more 0. A restyle with unchanged lines then differs in the key and the float is repainted, which a test proves against a full repaint. Alternative: bump the buffer's change counter by reloading the same lines; rejected, it records an undo state and replaces the strings the styles are kept for.

### Version

`MINOR` 12, `VERSION` "2.12"; `ManifestCheck.refusal` already accepts every older 2.x minor, so a 2.11 plugin loads unchanged.
