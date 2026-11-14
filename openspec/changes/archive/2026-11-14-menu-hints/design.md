# Design

## Context

`ShowKeyHints#open` builds a bordered `FloatSpec` anchored to the editor at row `screen_rows`, column `screen_cols`; `FloatWindow#place` cuts it and moves it inside the float margin, so the box stands at the bottom right. The palette is already centered by `FloatWindow#centered` (float-placement), which `place` reads at every arrange. `meaning` shows a prefix's group name, or `"+#{child.binding_count}"` when no `keymap.group` line names it. `ShowKeyHints#call` closes a shown float with its own `CloseFloat`, the three lines `HideKeyHints#call` holds; it tests the mode with the expression `HandleKey#grammar_mode?` holds; `HandleKey#call` tests `@key_hints.float_id != 0`; `Options#initialize` passes the literal 300 where `KEYHINTS_DELAY` names it.

## Goals / Non-Goals

Goals: the hints centered at the bottom; a name on every prefix row; one close, one grammar-mode test, one showing test, and the delay constant read.

Non-goals: the palette's rows, spans, and contrast, and the completion popup's padding (`palette-rows`); a full-width panel; the `screen_cols < 6` guard (`discoverability-tidy`).

## Decisions

### The panel is the centered flag on the hints float

`open` keeps its sizing and sets `float.centered = true` before opening, with column 0 in the spec, as the palette does. The row stays `screen_rows`, so `place` moves the box up to the margin above the message row: the panel stands at the bottom, centered at show and after a resize under every border style, with no new placement code. Alternative: a full-width bar; rejected, since a wide empty box over the text hides more than it shows for the usual 5 to 10 rows.

### An unnamed prefix is named by the actions under it

`meaning` of a prefix with no group name walks the child's subtree (a private recursive `segment` in `ShowKeyHints`, returning the first dotted segment of the action names below, `""` when a remap or a different segment is met) and shows that segment, or `group` when it is empty. A plugin action reads `plugin`, its first segment, which is true and short. The walk runs only when the hints open, never on a key, so the bench is unchanged. Alternative: keep `+N` beside a name; rejected, the count was the text the user found meaningless. `KeymapNode#binding_count` stays for its domain test and the keymap's callers.

### One close, one mode test, one showing test

`ShowKeyHints` takes `hide_key_hints: HideKeyHints` in place of `close_float:` and calls it first; `HideKeyHints#call` already returns when nothing shows. `Domain::Mode.grammar?(mode)` holds the normal, operator-pending, and visual test; `HandleKey#grammar_mode?` and `ShowKeyHints#call` call it. `HandleKey#call` asks `@key_hints.showing?`, a method returning a comparison, which allocates nothing, so the hints still cost nothing while none shows. `Options#initialize` passes `KEYHINTS_DELAY`.

## Risks / Trade-offs

- A centered panel may cover the cursor's line on a short screen, as the bottom-right float could; the next key closes it at once, as before.
- `group` for mixed prefixes is a generic word; a `keymap.group` line names it, as the hints test shows.
