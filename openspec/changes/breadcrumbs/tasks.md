# Tasks

## 1. Domain

- [ ] 1.1 Add `option.breadcrumbs` (`auto`, `always`, `never`) to `Options`, proven by rows of `test/domain_options_config.rb`
- [ ] 1.2 Add `TabPage#file_window_count` and `TabPage#winbar?`, proven by `test/editor_breadcrumbs.rb`
- [ ] 1.3 Add the `SymbolRequest` record (languages, the text asked, the request in flight, the held symbols and the path at a row), proven by `test/editor_breadcrumbs.rb`

## 2. Winbar

- [ ] 2.1 Reserve the winbar rows in `ArrangeView`, add the `Winbar` painter and paint it in `FramePresenter`, wired in `EditorAssembly`, proven by `test/editor_breadcrumbs.rb`, `test/adapters_frame_presenter.rb`, and the updated split tests
- [ ] 2.2 Add `option.breadcrumbs auto` to `config/default.caratrc` and run `make gen-config`, proven by `test/config_sync.rb`

## 3. Symbols

- [ ] 3.1 Advertise and record `documentSymbolProvider`, send `textDocument/documentSymbol` at idle ticks from `JsonRpcLanguageGateway`, cancel overdue requests, and read answers with `SymbolOutline`, proven by `test/editor_breadcrumbs.rb` and `test/adapters_language_gateway.rb`

## 4. Neighbours by rectangles

- [ ] 4.1 Name the layout-rectangle rule in `test/domain_layout.rb` and add the nested split through keys in `test/editor_windows.rb`, with the `windows` spec scenario and the `docs/compatibility.md` row

## 5. Docs and checks

- [ ] 5.1 Update `docs/compatibility.md`, `docs/architecture.md`, `docs/codebase-map.md`, and `README.md`, checked by `make docs-lint` and `make gates`
- [ ] 5.2 Record the plan notes in `docs/backlog.md` (the two fixed entries removed, the four widened or corrected, the raised-again Low), checked by `make docs-lint`
- [ ] 5.3 Run `make test`, `make lint`, `make diagnose`, `make bench` on `lh` and `j`, `make gates`, and `make spec-validate`, all passing
