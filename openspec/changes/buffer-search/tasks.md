# Tasks

## 1. Patterns and matching in the domain

- [x] 1.1 Add `Domain::SearchPattern`, `Domain::VimPattern` (translation of the magic modes, case flags, size cap, Vim's errors), proven by the table of `test/domain_vim_pattern.rb`
- [x] 1.2 Add `Domain::SearchBudget`, `Domain::SearchHit`, and `Domain::Search` (forward and backward search with count and wrap, line matches, illegal bytes, the budget), proven by `test/domain_search.rb`
- [x] 1.3 Add `Domain::History`, `Domain::LastSearch`, and `Domain::SearchPrompt`, and the `search` member of `Registers` read by `"/`, proven by `test/domain_search.rb` and `test/domain_registers.rb`
- [x] 1.4 Add the four search options to `Options` with Neovim's defaults, proven by `test/domain_options_config.rb`

## 2. Search keys

- [x] 2.1 Add the `:search` kind to `CommandGrammar` (the pattern argument), proven by `test/domain_grammar.rb`
- [x] 2.2 Add `FindMatch`, `JumpToMatch`, `OpenSearchPrompt`, and `SearchHandler`; wire `HandleKey`, `ExecuteCommandLine`, `CancelCommandLine`, `EnterCommandLine`, and `EditorAssembly`; remove the reserved actions from `MessageHandler`; proven by `test/editor_search.rb`
- [x] 2.3 Use a search as an operator's motion in `Operate` (exclusive, register 1, dot repeat), proven by `test/editor_search.rb`
- [x] 2.4 Bind the search keys in the normal, operator-pending, and visual maps and `<Up>`/`<Down>` in the cmdline map of `config/default.caratrc`, run `make gen-config`, and list the actions in `docs/actions.md`, proven by `test/use_cases_actions.rb` and `test/config_sync.rb`

## 3. Prompt, history, options, and :noh

- [x] 3.1 Add `RecallHistory` and `PreviewSearch` (incsearch) and call the preview from the command-line edits, proven by `test/editor_search.rb` and `test/editor_cmdline.rb`
- [x] 3.2 Handle `ignorecase`, `smartcase`, `hlsearch`, and `incsearch` in `SetCommandHandler`, and add `NohlsearchCommandHandler`, proven by `test/use_cases_ex.rb` and `test/editor_search.rb`
- [x] 3.3 Add `/` to the `:registers` order and remove the backlog entry for the search register, proven by `test/editor_registers.rb`

## 4. Highlighting

- [x] 4.1 Add the `Search` and `IncSearch` groups to `Highlight` and both themes, proven by `test/domain_theme.rb`
- [x] 4.2 Paint the matches in `FramePresenter` with the stamp in `PaintedRows`, proven by `test/adapters_frame_presenter.rb` and `test/editor_search.rb`

## 5. Benchmark and documents

- [ ] 5.1 Add the `n` scenario to `bench/keys.rb` and check that `lh` allocates what it did on `main`, by `make bench-budget` and `make bench SCENARIOS="lh n"`
- [ ] 5.2 Document the search rows in `docs/compatibility.md`, the engine notes in `docs/spinel-notes.md`, the files in `docs/codebase-map.md`, the backlog entries, `README.md`, and the status line of `CLAUDE.md`, checked by `make docs-lint` and `make gates`
- [ ] 5.3 Run `make test`, `make lint`, and `make gates`, all passing

## Workflow follow-up

- Archive with `openspec archive buffer-search -y`, record the plan and metrics history, push, and open the pull request.
