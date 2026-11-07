# Design

## Context

`JsonRpcLanguageGateway#published` keeps each file's diagnostics per server by URI (`Diagnostic` row, column, severity, message), the message through `ControlText.strip` at 500 bytes; `diagnostics(path)` has no production caller. `StatusSlots` has the four counts and `StatusBar` draws them, but nothing writes them. The number column draws `Buffer#sign_at(row)`, the sign of the layer of lowest priority number that marks the row; layers are kept per owner and moved with the lines by every splice. `FramePresenter#paint_message` reads the state only. The gateway runs only on idle ticks (`InputController#pump`), with the state, so it knows the icon set (`state.options.icons`). Scout packs: rendering, ports and language services, composition and state, at eb63fb4.

## Goals / Non-Goals

**Goals:** the three displays the roadmap names; no allocation per key and no work per key with no diagnostics; diagnostic text drawn only stripped, bounded, and on one line.

**Non-Goals:** diagnostic navigation, a float with the full text, virtual text, per-severity sign colors, drawing by column.

## Decisions

### The buffer keeps what is shown

`Buffer` gains `diagnostics` (the list last published for its file) and `diagnostic_marks` (one integer per line, 0 or the 1-based index of the line's most severe diagnostic, a lower severity number being more severe, the first published on a tie). `set_diagnostics(list, glyphs)` stores both and replaces the sign layer of owner `lsp.diagnostics` (a dot no plugin name has) at priority -1, so the diagnostic sign wins over plugin signs (registration positions from 0); `glyphs` are the four icons by severity. A diagnostic on a row past the buffer's end counts but marks nothing. `clear_diagnostics` empties both and removes the layer. `shift_signs`, which every splice and undo already calls, moves `diagnostic_marks` with the sign layers (skipped when empty), so the message and the sign stay on the line they were published for while the user edits until the server publishes again. `diagnostic_at(row)` answers the marked diagnostic or nil, with no allocation; an empty mark array answers nil at once.

Alternatives: reading the gateway from the presenter (the presenters read the state only, and the gateway is not in the core); looking up the cursor's row in the list each frame (does not follow edits, and costs the list's length per key when diagnostics exist).

### The gateway applies a publish at the idle tick

`published` remembers the URI in `@published`; `poll`, after the drain, hands each remembered URI's list to every listed buffer whose path makes that URI (`apply`), with the icon set from the state, then counts the current buffer's diagnostics into the slots with `StatusSlots#count_diagnostics(list)` (errors through `Diagnostic#error?`), which answers whether a count changed, so the screen redraws. With nothing published and an empty list the tick allocates nothing more than before. `restart`, and `start` dropping a crashed or stopped server, clear the diagnostics of every buffer of that file type, as the server's stored ones are gone. A crash keeps them, as before, until the restart.

### The message row

`paint_message`, after the pending message, the command line, the list prompt, and the mode indicators, in normal mode draws `buffer.diagnostic_at(cursor.row)` of the current window, in `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, or `DiagnosticHint` by severity, cut by the frame at the screen's width; the showcmd text is drawn over its right end as over any message.

### One bounded line

`ControlText.line(text, limit)` is `strip` with a line feed, carriage return, or tab turned into one space before the cut, so "a\nb" reads "a b", not "ab"; the gateway uses it for diagnostic messages. The frame's own guard (`Frame#put_from` stores a control as U+FFFD) stays the last line of defense.

## Risks / Trade-offs

- The counts and a publish's signs wait for an idle tick, as the lsp slot does: a fast typist sees them after the next pause.
- Marks are an integer per line for a buffer with diagnostics: a 100,000-line file with one diagnostic keeps 100,000 integers, as one plugin sign does today.
- A `:set icons` change redraws the bar's counts at once but the signs only at the next publish.
