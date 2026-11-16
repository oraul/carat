# Tasks

## 1. Sync kind

- [ ] 1.1 Add `sync_kind` and `texts` to `Domain::LanguageServer` (`carat/domain/language_server.rb`), `forget` dropping the text; read `capabilities.textDocumentSync` (number or options `change`) in `JsonRpcLanguageGateway#initialized`; proven by `test/adapters_language_gateway.rb` "No sync kind sends no change" and "The options object announces the kind" rows.

## 2. Ranged changes

- [ ] 2.1 Send the whole text only under kind 1, one ranged change under kind 2 from the stored lines (`JsonRpcLanguageGateway#sync_buffer` and a private range builder), nothing under 0; proven by the table "Incremental changes reproduce the buffer" (inserts, deletes, multi-line, non-ASCII, undo) applying the ranges to the opened text, and "Open, change, save, close" under kind 1.
- [ ] 2.2 Announce kind 2 in the canned servers of `test/adapters_server_completions.rb` so "the typed text is sent before the request" still sees a `didChange`.

## 3. Docs

- [ ] 3.1 Update the gateway's header comment and `docs/codebase-map.md` area 17 flow; run `make gates`, `make spec-validate`, and the allocation check against lh 26.0, j 27.0, insert 26.0.
