# Design

## Context

Hover (`quick-docs`) shares a `Domain::HoverRequest` between its use cases and `JsonRpcLanguageGateway`, which sends the ask at an idle tick and marks the answer arrived for `InputController` to show. Completion (`completion-request`) adds the debounce: a new serial is scheduled `DEBOUNCE` after the tick that first sees it. Insert mode inserts an unbound printable key in `HandleKey#insert_literal`; `HandleKey#call` ends in per-key checks that cost one comparison when nothing shows. The periodic quality review at b0dd342 found that hover shows an older request's answer when it is drained in the same tick a newer ask is first seen (`hovered`, gateway line 674): the queue is drained before the send, and the answer still matches the id in flight.

## Goals / Non-Goals

Goals: the signature of the call the cursor is in, the active parameter marked, following the cursor, closed outside the call; asynchronous, debounced, stale answers never shown; untrusted text bounded; nothing per key while no call is followed.

Non-goals: the documentation of the signature, overload cycling, multi-row calls, a manual trigger key (proposal).

## Decisions

### One shared request record

`Domain::SignatureRequest`, a `Struct` like `HoverRequest`: the anchor (window, buffer, row, the byte column of the `(`, and the cursor column asked at), the serials `want`, `seen`, `sent`, the request in flight (`sent_id`, `language`, `due`, `deadline`), the answer (`label`, `mark_from`, `mark_to` as byte offsets, `arrived`), the languages whose server gives signature help, and the float id. `active?` is `open_col >= 0`, the one comparison `HandleKey#call` makes. `ask` records the anchor under a new serial; `stop` forgets the anchor under a new serial, so the gateway cancels what is in flight and the answer to it is dropped; `keep(prefix, parameter, suffix)` reads the three pieces through `ControlText.plain` within `LABEL_LIMIT` (1,024) bytes and records the marked range between them, so the offsets are those of the cleaned label. `SignatureRequest.open_paren(line, col)` scans back from the cursor at most `SCAN_LIMIT` bytes and answers the byte column of the innermost unclosed `(`, -1 for none. `EditorAssembly` builds it once and hands it to the gateway, the three use cases, `HandleKey`, and `InputController` as their own keyword, not through another collaborator's reader (a periodic quality finding against hover).

### Triggered by two characters, followed by one comparison

`HandleKey#insert_literal` calls `RequestSignature` only when the typed code is `(` or `,`: two integer comparisons on the typed path. `RequestSignature` returns unless the buffer's file type is among the signature languages (an `include?` on a short array), then scans for the open `(` and asks. After each key `HandleKey#call` calls `FollowSignature` only when `active?`. `FollowSignature` stops (closing the float) when insert mode was left, the layout window, its buffer, or its row changed, or no unclosed `(` precedes the cursor; asks again when the open `(` or the cursor column changed; and forgets a float another path closed. The old float stays until the new answer replaces it, so the float does not flicker while typing an argument.

### The gateway sends debounced and drops stale answers

`send_signature` runs in `poll` after the hover: a new serial sets `seen`, `due = now + DEBOUNCE`, and cancels the request in flight; a stopped ask is marked sent at once, so the services wait no longer; a request in flight is cancelled at its `deadline` (`ANSWER_LIMIT` after its sending); once due, the request is sent only when insert mode, the layout window, buffer, row, and cursor column still match the ask and the server gives signature help. `signed` is called only for the id in flight and the server's language, as hover's answer is, and also drops the answer when `sent != want`, that is when a newer ask was recorded after it was sent: the order the hover path fails. Cancelling goes through a new private `cancel_request(language, id)`; the three older copies stay as they are and the backlog entry names the helper they should call.

The answer is read in the adapter: `signatures` must be a non-empty array; `activeSignature` within it, else 0; the signature's `activeParameter`, else the help's, within its `parameters`, else none; a parameter label as a string is found with `byteindex` in the raw label, as a pair of integers it is two UTF-16 offsets converted to byte offsets walking the raw label, kept only when `0 <= from <= to <= length`. The raw label is split there into three pieces before cleaning, so no offset is applied to cleaned text.

### A one-row float with marked columns

`ShowSignature` closes the previous float and, when the answer is still for the followed anchor in insert mode, opens a bordered float of one row over a scratch buffer owned by `:signature` (no plugin can own a name with a colon), anchored at the cursor, row offset -3 (above) or 1 when the cursor's screen row leaves no room above, width the label's display width capped at the screen's columns minus two, z 900. An empty label stops the following. `FloatWindow` gains `mark_from` and `mark_to`, display columns of the float buffer's first row, -1 for none; `FramePresenter#paint_float_row` fills them with `Visual` after the row's group. A changed mark opens a new float, whose new window id is in the float key, so no key change is needed.

## Risks / Trade-offs

- Every key inside a followed call asks the server again after the debounce; a typing user sends one request per pause, as completion does.
- The row scan ignores strings and comments, so a `(` inside a string can start a follow; the server then answers no signature and the float closes.
- A label wider than the screen hides a later parameter's mark; the float shows the label's start.
