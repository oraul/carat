# Tasks

## 1. Plan bookkeeping

- [x] 1.1 `docs/backlog.md`: add the 11 entries of `build/plan/backlog.md`; reword the `BufferList` entry, widen the tab width entry, mark the two check-isolation entries queued in `check-runner-safety` (with the cd87445 Low (5) at `tools/run_state.sh:529`), and add the check-isolation evidence to the refused backup pushes entry (proved by `make docs-lint`)

## 2. Markdown reader

- [x] 2.1 `Domain::MarkdownText.rows`: markup out, nesting and size capped, escape sequences dropped, wrapped (`test/domain_markdown_text.rb`)

## 3. Documentation records and the source

- [x] 3.1 `Domain::CompletionDocs` held by `CompletionRequest#docs`, with `pick`, `text_at`, `waiting?`, `clear` (`test/adapters_server_completions.rb`, the record rows)
- [x] 3.2 `CompletionPort#documentation(list, index)`, `ServerCompletions`, `FixedCompletions#document`; `CompletionMenu#origin` and the documentation float members (`test/editor_completion.rb`)

## 4. The float

- [x] 4.1 `ShowCompletionDocs` beside the popup, called by `ShowCompletion`; `CloseCompletion` closes it; `InputController` refreshes on its arrival; wired in `EditorAssembly` (`test/editor_completion.rb`, `test/adapters_assembly.rb`)

## 5. The gateway

- [x] 5.1 `JsonRpcLanguageGateway`: keep the server's items, read answer documentation, advertise markdown and resolve support, `resolveProvider`, debounced `completionItem/resolve`, the routed answer, `waiting?` (`test/adapters_server_completions.rb`)

## 6. Docs and checks

- [x] 6.1 `docs/codebase-map.md`, `docs/architecture.md` port table, `docs/compatibility.md`, `README.md` (`make docs-lint`, `make gates`)
- [ ] 6.2 `make lint`, `make diagnose`, `make test`, `make spec-validate` pass
