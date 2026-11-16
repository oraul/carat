# Proposal

## Why

Every `textDocument/didChange` carries the whole text (`carat/adapters/json_rpc_language_gateway.rb:1311`), whatever the server announced. ruby-lsp 0.26 announces `textDocumentSync` change 2 (incremental) and then ignores a content change without a range, so its copy of the document goes stale after the first edit and a completion request fails with `InvalidLocationError`. This is the T2 fix `lsp-incremental-sync`, pool item 1 of `docs/queue-backlog.md`; it is outside the roadmap of `docs/architecture.md` section 12, a defect of the delivered language-server client.

## What Changes

- The initialize result's `capabilities.textDocumentSync` is read, as a number or as the `TextDocumentSyncOptions` object's `change`, and kept per server.
- Kind 2 (incremental): each `didChange` carries one ranged content change, zero-based lines and UTF-16 code unit characters, replacing the span between the first and the last character that differ from the text last sent with the buffer's text there; applied to the text the server holds it reproduces the buffer after any edits, multi-line ones and undo included.
- Kind 1 (full): the whole text, as now.
- Kind 0, an unknown kind, or none announced: no `didChange`; `didOpen`, `didSave`, and `didClose` are still sent.
- Minor assumptions: a kind 2 sync whose text equals the text last sent (an edit undone before the idle tick) sends nothing and keeps the version; the canned servers of the completion tests announce kind 2, as ruby-lsp does.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-server`: the requirement "The server is told about the documents" sends `didChange` by the sync kind the server announced instead of always with the whole text.

## Impact

- Domain: `LanguageServer` gains `sync_kind` and `texts` (the lines last sent per URI under kind 2), forgotten with the document.
- Adapters: `JsonRpcLanguageGateway#initialized` reads the sync kind; `sync_buffer` sends the whole text, a ranged change, or nothing.
- Tests: `test/adapters_language_gateway.rb` gains the table-driven sync-kind tests over canned servers announcing 2, 1, 0, and the options object; `test/adapters_server_completions.rb` announces kind 2.
- Docs: `docs/codebase-map.md` area 17 flow names the sync kinds; the gateway's header comment.
- README.md: unchanged, it says only that the server is told about the open files, which still holds.
- docs/architecture.md: unchanged, its sections 6 and 8 do not describe the document sync messages.
- Performance: the edit path is untouched, the work runs only at an idle tick with a running server, so lh, j, and insert keep their allocations.
- Out of scope: sending one content change per buffer edit (the records can be reverted without a record, so the text diff is the faithful source), the `openClose` and `save` options, and pull diagnostics.
