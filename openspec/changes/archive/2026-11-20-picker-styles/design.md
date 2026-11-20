# Design

## Context

A plugin float is a `Domain::FloatWindow` over a plain `Domain::Buffer` the plugin owns (`owner` set, so a scratch buffer that keeps no undo states), outside the buffer list, built by `WindowRequests#open_float`. Its title is `FloatSpec#title`, which the frame presenter draws, mirrored in the buffer's `title`. `set_scratch_lines` already replaces a scratch buffer's lines through `replace_lines` (one transaction, `Buffer#reload`), but it finds the buffer by title among the listed ones, so it cannot reach a float. The finder's `refresh` closes both floats and opens new ones on every call.

## Decisions

### One request for lines and title

`set_float_lines(window, lines, title)` takes both, as the finder changes both on every key; a plugin that keeps the title passes it again. No `FloatOptions` member is added, so a 2.x plugin that builds `FloatOptions` positionally keeps compiling. The request belongs to the window family: `Host#set_float_lines`, `PluginLink#set_float_lines` (refusal check, then forward), and `WindowRequests#set_float_lines(name, id, lines, title)`.

### Ownership and lookup

The request resolves the float as `move_float` and `close_float` do, through `own_float_tab` (any tab page, 0 for the current window, the buffer's owner compared), so another plugin's float, the completion popup, a layout window, and an unknown id all fail with "No float N".

### The refill

`replace_lines` reloads the buffer in one transaction with copied strings (empty lines leave one empty line, as `Buffer#reload` does), then the buffer's title and the spec (`FloatSpec#titled`, a new Data value with only the title changed) take the new title, and the float window's cursor, selection anchor, top row, and left column go back to the start, as a reopened float had them, so a shorter list never leaves the cursor or a selection in it past the last line. The window id, box, z order, focus, and the float's position in its layer stay. The presenter draws the buffer's new text because its change count moved, which the test proves against a full repaint.

### The finder

`refresh` computes each box as before and calls `show_float(host, id, box_key, options, lines)`: when the id is non-zero and the box key (column, height, width) equals the one the float was opened with, it refills the float with `set_float_lines` and keeps the id; otherwise, or when the refill fails, it closes the old float and opens a new one. A preview that should not show is closed. `close_floats` (cancel, pick) is unchanged. Alternative: move and resize floats too; rejected, no request resizes a float and the box only changes on a resize.

### Version

`MINOR` 11, `VERSION` "2.11"; `ManifestCheck.refusal` already accepts every older 2.x minor, so a 2.10 plugin loads unchanged.
