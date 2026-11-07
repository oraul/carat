# Proposal

## Why

The completion popup exists but its production source is never ready, so outside the tests the editor shows no popup: nothing asks the language server. This delivers the server side of the completion menu of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 1, goal 2). It also folds the periodic quality finding that a failed initialize marks a server ready, and the one that the language services are read only after a pause of 0.25 seconds, so a reply would show only once the user stops typing.

## What Changes

- `ServerCompletions` becomes a real source: ready for a buffer when its file type's server runs and advertised a completion provider; asked for a word it answers the server's last answer for that word, or records the word as wanted and answers an empty list at once, so no key waits.
- The language gateway sends `textDocument/completion` for the wanted word at an idle tick once no new word was wanted for 0.1 seconds (the debounce), after the document's `didChange`, at the cursor in UTF-16 units; at most one request is in flight.
- A request whose word is no longer wanted is cancelled with `$/cancelRequest`, and an answer that is not for the request in flight is dropped; a request unanswered after two seconds is cancelled too.
- An answer is bounded and untrusted: at most 200 items read, each label, detail, and insert text (`textEdit.newText`, then `insertText`, then the label) through `CompletionItem.from_source`, which drops escape sequences and controls and cuts each string; LSP kinds map to the menu's kinds.
- An answer that arrives fills the popup at the idle tick without another key, and while a word is wanted or a request is in flight the input waits at most 0.02 seconds between keys before the services are read, so a reply arriving while the user types shows before the next key.
- A failed initialize (an `error` member, or no result object) no longer marks the server ready: it is stopped as crashed, the slot names `:LspRestart`, and nothing more is sent to it.
- The initialize request advertises the completion capability without snippets.
- Docs: the map entries and Designs lines, and the backlog entries the plan names (the PR footer entry updated, the Frame comment entry removed, the Designs and `ControlText.cleaned` entries extended, nine new entries).

Out of scope: the selected item's documentation (`completion-docs`), incremental sync, `isIncomplete` re-requests while the typed part grows, trigger characters, snippets and text edits over another range than the typed part, and a debounce option.

Assumptions: the debounce is 0.1 seconds and the answer limit two seconds, constants rather than options, since the queue item asks for neither option. A server's text edit replaces the typed part with its `newText`, as the menu already inserts an item over the typed part. A failed initialize reads as a crash, since `:LspRestart` is what the user can do about it, rather than a new slot state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `completion`: the language server is the editor's source: debounced requests, cancelled when stale, answers bounded and untrusted, and an answer fills the popup without a key.
- `language-server`: a failed initialize leaves the server not ready and sends it nothing more.

## Impact

- New: `carat/domain/completion_request.rb`; `test/adapters_server_completions.rb`.
- Changed: `CompletionPort` (`request`), `LanguageServicePort` (`waiting?`), `ServerCompletions`, `FixedCompletions`, `FakeLanguageServices`, `JsonRpcLanguageGateway`, `ShowCompletion`, `InputController`, `EditorAssembly`, `test/adapters_language_gateway.rb`, `test/adapters_assembly.rb`, `docs/codebase-map.md`, `docs/backlog.md`, `docs/compatibility.md` if it lists completion.
