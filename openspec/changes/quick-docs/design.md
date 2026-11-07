# Design

## Context

The gateway (`JsonRpcLanguageGateway`) works only at idle ticks and matches responses by id against the request kinds it tracks: initialize, completion, and resolve (`receive`). The completion source shares a `CompletionRequest` record with it, and `InputController` refreshes the popup when the record says an answer `arrived`. `MarkdownText.rows` already reads untrusted markdown into plain rows under size, row, and nesting caps for the completion documentation float. Floats are windows over a buffer (`OpenFloat`, `CloseFloat`), focused with `FloatLayer#enter`, scrolled by `ArrangeView` like any window, and `Esc` in normal mode closes the topmost one (`float.close`).

## Goals / Non-Goals

**Goals:**
- One shared record and one request kind more in the gateway, the same idle-tick shape as completion.
- A float the user scrolls with the keys they already know, by entering it.
- No work per key while no hover float shows.

**Non-Goals:**
- Colors inside the float or the pinned split (the follow-up `quick-docs-styles`, see the proposal).
- A float-local keymap (`q` to close) or `keywordprg`.

## Decisions

### A shared HoverRequest record, as CompletionRequest is

`Domain::HoverRequest` is a `Struct` built once in `EditorAssembly` and given to the gateway, the `docs.*` use cases, `HandleKey`, and `InputController`. `RequestHover` (`K`) records the window, buffer, and cursor under a new serial (`ask`); the gateway's `hover` step, at the next idle tick, sends `textDocument/hover` for that serial when the current window, buffer, cursor, and mode still match, cancels the request in flight first, and cancels one unanswered `ANSWER_LIMIT` seconds after it was sent (its own deadline, not one a later ask moves, the defect the backlog records for resolve). The answer to the request in flight only is read (`hovered`): the contents become one markdown text (a markup content's value, a marked string, a `{language, value}` pair as a fenced block, at most `PART_LIMIT` parts of a list joined by blank lines, the text cut to `MarkdownText::RAW_LIMIT` bytes as it grows), `arrived` is set, and an error or empty contents arrive as the empty text. `languages` lists the servers whose initialize advertised `hoverProvider`, which `RequestHover` checks before asking. Alternative: a hover port like `CompletionPort`; rejected because nothing but the gateway answers hover, and a record keeps the core free of JSON as completion's does.

### ShowHover at the idle tick, FollowHover per key behind one comparison

`InputController#pump` calls `ShowHover` when the record's `arrived` is set, beside the completion refresh. It drops the answer when the anchor moved, shows `No information available` for an empty text, and otherwise opens the float: rows from `MarkdownText.rows` at the width of `min(80, screen columns - 2)`, a border, anchored at the cursor one row below, or above when only above has the room, z 50, and records its id in the record. `HandleKey#call` ends with `@follow_hover.call(state) if @hover.float_id != 0`, the only per-key cost; `FollowHover` forgets a float another path closed, keeps a focused (entered) one, and closes it when the layout window, its buffer, its cursor, or the mode differ from the anchor. Alternative: an `ArrangeView` hook; rejected because it runs before every render as well, and arranging should not close windows.

### K enters the float; pinning copies its rows into a scratch split

`RequestHover` enters the float (`FloatLayer#enter`) when it shows, as Neovim's second `K` does, so scrolling is the window's own. `PinHover` builds a scratch buffer (owner `:docs`, title `[docs]`) over a copy of the float's lines, closes the float, splits with `SplitWindow` at the rows' height capped at 10, and loads the buffer into the new window. A scratch buffer is never written and never counts as unsaved work, so `:q` and `:qa` are not refused for it.

### Wrapping keeps a row's prefix whole

`MarkdownText.wrapped` takes a space as a break point only when a character other than a space precedes it in the segment past the prefix (the leading spaces, bullets, and bars), else cuts on a character boundary, so a code row, a bullet, or a bar is never alone on a row.

## Risks / Trade-offs

- [A server that hovers slowly holds the idle wait at 0.02 seconds] → `waiting?` includes the hover record only while a request is to send or in flight, at most two seconds.
- [A float under the cursor closes on any cursor move, even one the user meant to read with] → entering it with `K` keeps it, and pinning keeps the text.
- [Plain rows lose the styling the brief asks for] → recorded as the follow-up `quick-docs-styles` in `docs/backlog.md` with its outline.
