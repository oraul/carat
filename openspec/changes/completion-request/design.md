# Design

## Context

`completion` added the popup over `Ports::CompletionPort` (`ready?`, `candidates`), driven in the tests by `FixedCompletions`; the production `ServerCompletions` is never ready. `JsonRpcLanguageGateway` speaks JSON-RPC only at idle ticks (`InputController#pump` when a read of 0.25 seconds returns nothing), sends no request but `initialize` and `shutdown`, keeps no pending request, and marks a server ready on any response to `initialize`, an error included (ports-drivers-and-language-services scout pack). `ShowCompletion#call(state, typed)` asks the source once per word (buffer, row, start column) and filters locally; `CloseCompletion` forgets the word, so the next typed character asks again (edit-path scout pack).

## Goals / Non-Goals

**Goals:**

- The popup filled from the server with no key waiting on it; requests debounced; a stale one cancelled and its answer dropped; answers bounded and stripped; a failed initialize never ready.
- No allocation and one or two reader calls per typed key when no server completes, so `insert` holds 35.0.

**Non-Goals:**

- Documentation beside the list, incremental sync, `isIncomplete` re-requests, trigger characters, snippets, a debounce option.

## Decisions

### One shared request record

`Domain::CompletionRequest` is a `Struct` record holding the asynchronous ask: the wanted word (buffer id, row, start column) and its serial `want`, the serial the gateway scheduled (`seen`) with its deadline `due`, the serial last sent (`sent`) with the request id in flight (`sent_id`, 0 for none) and its server's language, the serial whose answer is held (`answered`) with the `CompletionList`, the `arrived` flag, and the languages whose running server completes. The source writes the want; the gateway reads it and writes the rest. `CompletionPort#request` answers the record a source shares with the language services: `ServerCompletions` builds it with no arguments, `FixedCompletions` holds one nobody fills, and `EditorAssembly` hands `completions.request` to the gateway, so `bin/carat.rb` keeps passing one source and the harness keeps its double. Alternatives: passing the gateway to `ServerCompletions` is impossible since the assembly builds the gateway after the source; building the source in the assembly would take the double away from the popup tests.

### The source never waits

`ServerCompletions#ready?(buffer)` is whether the buffer's file type is among the completing languages, an `include?` on an empty array with no server. `candidates(buffer, row, col)` answers the held list when the record answered the current want for that word; otherwise it records the word (a new serial unless it is already the wanted word) and answers its one empty list. The popup then closes for no match, which forgets the word, so the arrival can fill it later.

### The gateway sends at an idle tick, debounced

`poll` runs `complete` after the document sync, so `didChange` precedes the request. A new serial is scheduled `DEBOUNCE` (0.1 s) after the tick that first sees it, and a request in flight for an older word is cancelled at once with `$/cancelRequest` and forgotten. When the deadline has passed the serial counts as sent; the request goes out only if the current buffer, row, and mode still hold the word and its server runs and completes, at the cursor's line and UTF-16 column (the default position encoding; the column counts the line's characters before the cursor, two for one outside the basic plane), with `triggerKind` 1. A request in flight longer than `ANSWER_LIMIT` (2 s) past its deadline is cancelled, so a silent server cannot keep the input's short wait forever.

### Answers are bounded at the boundary

A response matches only when its id is the one in flight and it came from that server; any other response is dropped, which drops the answer of a cancelled request. An error or a non-list result is an empty answer. The result is an array or an object with `items`; at most `CompletionList::LIMIT` items are read, each a hash with a string `label` becoming `CompletionItem.from_source(label, kind, detail, text)`: the kind from the LSP number through a table of 26 names (interface, enum, and struct read as class; value, enum member, and constant as constant; the rest without an icon as text), the text from `textEdit.newText`, else `insertText`, else the label. `from_source` reads at most 4,096 raw bytes of each string, drops escape sequences and controls, and cuts the label and detail to 80 bytes and the text to 200. The menu cleans again when it fills, which is idempotent.

### The arrival refreshes the popup

The gateway sets `arrived`. `ShowCompletion#call` treats an arrival like a typed character: it returns at once unless the popup shows, a character was typed and the source is ready, or `arrived` is set, which it clears. `InputController` calls it after `poll` at the idle tick, and answers true for a redraw when an answer arrived.

### A short wait while the services wait

`LanguageServicePort#waiting?` answers whether a wanted word is not yet sent or a request is in flight. `InputController#next_timeout` then waits at most `SERVICE_TIMEOUT` (0.02 s) instead of 0.25 s, so between two keys typed 0.1 s apart the services are read and an answer fills the popup before the next key. Without a want nothing changes, and a key still never reaches the services.

### A failed initialize is a crash

A response to `initialize` with an `error` member or without a result object stops the server as crashed: the slot names `:LspRestart`, `initialized` and the documents are never sent, and the language never completes. A crash or stop also drops the language from the completing ones and forgets a request in flight to it.

## Risks / Trade-offs

- [A server answering slowly shows the popup late] → the popup fills whenever the answer arrives while the word is current; typing on filters the held answer locally.
- [The answer is for the word's position when sent, not as typed later] → the menu filters by the typed part, as for any source; `isIncomplete` re-requests are left out.
- [Polling every 0.02 s while waiting costs wakeups] → only while a request waits, at most `ANSWER_LIMIT` past the debounce.
