# Tasks

## 1. The scan

- [ ] 1.1 Add `Domain::BufferWords` (`carat/domain/buffer_words.rb`): the forward and backward order over the current and the other listed buffers, word starts, prefix matching, duplicates, the 200-word and 1,000,000-byte bounds; rows in `test/editor_word_completion.rb`.

## 2. The popup

- [ ] 2.1 Move the popup float drawing from `ShowCompletion` into `UseCases::OpenCompletionPopup` (`carat/use_cases/completion/open_completion_popup.rb`), selecting the menu's selected row; keep a showing popup with an empty typed part for the same word; wire it in `EditorAssembly`; `test/editor_completion.rb` and `test/adapters_assembly.rb` pass.
- [ ] 2.2 Add `UseCases::CompleteWord` (`carat/use_cases/completion/complete_word.rb`) and the `completion.keyword_next` and `completion.keyword_previous` variants of `CompletionHandler`, bound with `keymap.insert <C-n>` and `<C-p>` in `config/default.caratrc` (`make gen-config`); rows in `docs/actions.md`; table-driven cases in `test/editor_word_completion.rb` for both directions, wrap-around, duplicates, other buffers, accepting, no match, the server popup's keys, and the large buffer.

## 3. Docs and checks

- [ ] 3.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` (section 5.1), and `docs/backlog.md` (the plan notes); `make docs-lint` and `make gates` pass.
- [ ] 3.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
