# Design

## Context

The completion popup (`completion`) is a float over formatted rows, refreshed by `ShowCompletion` after a typed character, after any key while it shows, and when the source's request marks an answer arrived at an idle tick. `completion-request` made the language server the source: `ServerCompletions` and `JsonRpcLanguageGateway` share one `CompletionRequest`, the gateway debounces and sends `textDocument/completion` at idle ticks and keeps a bounded, cleaned `CompletionList`. The parsed item kept only label, kind, detail, and text; nothing kept the server's item, so nothing could be resolved, and no documentation was read.

## Goals / Non-Goals

Goals: the selected item's documentation in a float beside the popup; lazy `completionItem/resolve` once the selection settles, at most one request per item of an answer; markdown as plain text; the text untrusted and bounded; no key waits and no key with no popup pays for it.

Non-Goals: per-span colors in the float, scrolling it, an option to turn it off, resolving other properties, the `K` hover popup.

## Decisions

### The gateway keeps the server's items; a record holds the documentation

`completed` keeps, beside each candidate it adds, the server's item as parsed (the `Hash`), in the gateway's own `@items`, cleared with each answer: the item is an adapter value sent back as the resolve request's params, never read by the core. `Domain::CompletionDocs`, a `Struct` record held by the `CompletionRequest` (`docs`), holds what the core reads: one documentation string per candidate of the held list (`texts`), a state per candidate (`known`: 0 to resolve, 1 asked, 2 held), the picked candidate (`index`) under a serial (`want`), the debounce (`seen`, `due`), the request in flight (`sent`, `sent_id`, `sent_index`), and `arrived`. An answer's item documentation (a string or a `MarkupContent`'s `value`) is held at once; an item without one is held empty when its server does not resolve. A new answer cancels the resolve in flight and resets the record, so a late answer never lands on the next list's items.

Alternative considered: keeping the raw item on `CompletionItem`. Rejected: the menu copies items through `from_source`, which is the boundary that cleans strings, and a domain value carrying a JSON tree crosses the layer rule.

### The source answers what it holds and records the pick

`CompletionPort#documentation(list, index)` answers the documentation the source holds for the candidate at `index` of `list`, `""` when none yet. `ServerCompletions` answers `""` unless `list` is the request's list by identity (`equal?`), since the menu may still filter an older list after a re-ask; then it picks the index and answers its text. `pick` records a new serial only when the index changes and, when the candidate needs no resolving, marks the serial handled at once, so a server that does not resolve never makes the services wait. `FixedCompletions` answers documentation a test sets with `document(index, text)`. `CompletionMenu#fill` keeps the list it copied (`origin`) for the question.

### The gateway resolves the settled pick at an idle tick

`poll` runs `resolve` after `complete`. A new pick starts its own debounce of `SETTLE`, 0.1 seconds, so a pick replaced within it is never sent. A pick past its deadline is sent only when its candidate is still to resolve, the list's server runs and advertised `resolveProvider`, and no resolve is in flight; the candidate is marked asked when sent, so it is never asked again for this answer, even when its request is cancelled as overdue (`ANSWER_LIMIT`, as for completion). A new pick does not cancel the request in flight: its answer is still kept for its item, and the new pick waits for it. `receive` routes a response to `resolved` only when its id is the resolve in flight and its server the list's. `waiting?` also answers the documentation's wait, so the input's short wait serves the deadline.

### One use case shows the float; ShowCompletion calls it

`ShowCompletionDocs#call(state)` runs at the end of every `ShowCompletion#call` that leaves the popup showing (after a typed character, after any key while it shows, and at an idle tick when the request or its documentation arrived). It asks the source for the selected candidate's documentation; when it is empty, the float closes. When the float already shows that candidate's same text beside the same popup float, nothing happens, so moving the selection costs one comparison. Otherwise the float is replaced: the rows from `MarkdownText`, a `FloatSpec` anchored at the cursor, no border, at z 999 under the popup's 1000, at the popup's row offset (below: from its first row; above: ending on the row above the cursor), its height cut to the rows free on that side. It stands at the popup's right edge, or at its left when the cursor's screen column plus that offset leaves less than its width and the left has the room. The menu holds the float's id and what it shows (`docs_float_id`, `docs_index`, `docs_text`, `docs_beside`); `CloseCompletion` closes it with the popup, and `ShowCompletion#reopen`'s refusal path goes through `CloseCompletion`, so no path forgets it. `InputController` refreshes on `docs.arrived` as on `arrived`, and `ShowCompletion` clears the flag before its guard, so a stale flag never makes every idle tick refresh.

### Markdown read as plain rows, in one pass, bounded

`Domain::MarkdownText.rows(text, width)` reads at most `RAW_LIMIT` (16,384) bytes, drops escape sequences (`ControlText.without_sequences`), and walks the lines once: a fence line (three backticks or tildes) toggles code and is dropped; a code line keeps its text indented by two spaces; any other line loses its block markers (up to `NEST_LIMIT`, 4, quote levels read as `│ ` each, deeper markers dropped; indentation capped at 4 levels of two spaces; `#` heading markers; `-`, `*`, `+` list markers as `• `; a thematic break as a rule) and its inline markup (backticks, `**` and `__`, `[text](target)` and `![alt](target)` as their text, a backslash escape as its character), each line cleaned by `ControlText.line`. Blank runs collapse, leading and trailing blank rows go, lines wrap at word boundaries to the width (a word longer than it is cut on a character boundary), and at most `ROW_LIMIT` (100) rows are kept. Every loop is linear in the bytes read; no part of the reader recurses, so nesting costs nothing beyond its cap.

## Risks / Trade-offs

- [The float covers text right of the popup] → it closes with the popup and stands on the left when the right lacks room.
- [A slow server delays the next item's documentation behind the one in flight] → bounded by `ANSWER_LIMIT`, and the one-request-per-item rule is the acceptance.
- [A plain-text document holding markdown markers loses them] → accepted; rare, and only layout changes.
- [Holding up to 200 server items] → they are the answer already parsed and bounded by the message limit; cleared with each answer.
