# Tasks

## 1. Safe completion values and matching

- [ ] 1.1 Add `ControlText.plain` (escape sequences dropped, then `line`) in `carat/domain/control_text.rb`; rows in `test/domain_fuzzy_match.rb`
- [ ] 1.2 Add `Domain::CompletionItem` (`from_source` cleans and bounds), `Domain::CompletionList` (at most 200), and `Domain::FuzzyMatch`; table rows in `test/domain_fuzzy_match.rb`
- [ ] 1.3 Add the twelve `kind_*` names to `Domain::Icons`; rows in `test/domain_icons.rb`

## 2. Source port, double, and adapter

- [ ] 2.1 Add `Ports::CompletionPort`, `Doubles::FixedCompletions`, and `Adapters::ServerCompletions`; pass the source to `EditorAssembly` from `bin/carat.rb`, `EditorHarness`, and `test/adapters_config_gateway.rb`

## 3. The popup

- [ ] 3.1 Add the `selected` member to `FloatWindow`, the `Pmenu` fill and the window id and selected row in the float key of `FramePresenter`; the reopened-float row in `test/editor_floats.rb`
- [ ] 3.2 Add `Domain::CompletionMenu` and the use cases `ShowCompletion`, `SelectCompletion`, `AcceptCompletion`, `CloseCompletion` under `carat/use_cases/completion/`, and `CompletionHandler`
- [ ] 3.3 Add the `completion` keymap layer to `Mode`, its lookup and the refresh in `HandleKey`, the bindings in `config/default.caratrc` and `make gen-config`, and the wiring in `EditorAssembly`
- [ ] 3.4 Add `test/editor_completion.rb`: a row per key (Enter, Tab, Ctrl-N, Ctrl-P, Down, Up, Esc), opening, filtering, closing, placement above, the row's cells and groups, undo, dot, the `.` register, untrusted text, and the candidate bound

## 4. Docs

- [ ] 4.1 Rows in `docs/actions.md` and `docs/compatibility.md`; map entries in `docs/codebase-map.md`; `docs/architecture.md` keymap layer note if it lists the keymap modes
- [ ] 4.2 Remove the backlog entry "A float reopened at the same box keeps the old float's text" and requeue "A failed initialize marks the language server ready" in `completion-request`
- [ ] 4.3 Run `make gates`, `make spec-validate`, `make docs-lint`, and the `insert` benchmark held at 35.0
