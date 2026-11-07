# Tasks

## 1. The shared request and the source

- [x] 1.1 Add `Domain::CompletionRequest` (`ask`, `answer_for?`, `completes?`, `waiting?`) in `carat/domain/completion_request.rb`; rows in `test/adapters_server_completions.rb`
- [x] 1.2 Add `CompletionPort#request` and implement it in `ServerCompletions` (ready for a completing language, the held answer or a recorded want) and `FixedCompletions`; add `LanguageServicePort#waiting?` and `FakeLanguageServices#waiting?`; rows in `test/adapters_server_completions.rb`

## 2. The gateway

- [x] 2.1 Stop a server whose `initialize` failed in `JsonRpcLanguageGateway`; rows in `test/adapters_language_gateway.rb`
- [x] 2.2 Advertise completion, record a completion provider, send the debounced `textDocument/completion`, cancel a stale or unanswered one, and read a bounded answer in `JsonRpcLanguageGateway`; pass the record and the clock from `EditorAssembly`; rows in `test/adapters_server_completions.rb`

## 3. The popup and the input

- [x] 3.1 Refresh on an arrival in `ShowCompletion`, call it after the idle poll and wait `SERVICE_TIMEOUT` while the services wait in `InputController`; end-to-end rows (answer with no key, between keys, debounce, cancel, bounds, no server) in `test/adapters_server_completions.rb`; the shared instances in `test/adapters_assembly.rb`

- [x] 3.2 Serve a held answer only to a word that begins with the typed part it was sent for (`CompletionRequest#word`, set at the send), and ask again for a want neither waiting nor answered; rows typing a second word at the same column and leaving insert mode within the debounce in `test/adapters_server_completions.rb`

## 4. Docs and records

- [x] 4.1 Map entries, the area 17 Flow sentence, and the Designs lines of areas 13 and 17 in `docs/codebase-map.md`
- [x] 4.2 Backlog: update the PR footer entry, remove the Frame comment entry, extend the Designs and `ControlText.cleaned` entries, add the nine plan entries in `docs/backlog.md`
- [x] 4.3 Run `make gates`, `make spec-validate`, `make docs-lint`, and the `insert` benchmark held at 35.0
