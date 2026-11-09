# Tasks

## 1. Domain

- [x] 1.1 Add `option.breadcrumbs` (`auto`, `always`, `never`) to `Options`, proven by rows of `test/domain_options_config.rb`
- [x] 1.2 Add `TabPage#file_window_count` and `TabPage#winbar?`, proven by `test/editor_breadcrumbs.rb`
- [x] 1.3 Add the `SymbolRequest` record (languages, the text asked, the request in flight, the held symbols and the path at a row), proven by `test/editor_breadcrumbs.rb`

## 2. Winbar

- [x] 2.1 Reserve the winbar rows in `ArrangeView`, add the `Winbar` painter and paint it in `FramePresenter`, wired in `EditorAssembly`, proven by `test/editor_breadcrumbs.rb`, `test/adapters_frame_presenter.rb`, and the updated split tests
- [x] 2.3 Count a split's rows from its leaf in `Layout#split` and add the winbar's row to a split count in `SplitWindow`, proven by `test/editor_breadcrumbs.rb` and `test/use_cases_arrange_view.rb`
- [x] 2.2 Add `option.breadcrumbs auto` to `config/default.caratrc` and run `make gen-config`, proven by `test/config_sync.rb`

## 3. Symbols

- [x] 3.1 Advertise and record `documentSymbolProvider`, send `textDocument/documentSymbol` at idle ticks from `JsonRpcLanguageGateway`, cancel overdue requests, and read answers with `SymbolOutline`, proven by `test/editor_breadcrumbs.rb` (the initialize capability, the requests, and the answers)

## 4. Neighbours by rectangles

- [x] 4.1 Name the layout-rectangle rule in `test/domain_layout.rb` and add the nested split through keys in `test/editor_windows.rb`, with the `windows` spec scenario and the `docs/compatibility.md` row

## 5. Docs and checks

- [x] 5.1 Update `docs/compatibility.md`, `docs/architecture.md`, `docs/codebase-map.md`, and `README.md`, checked by `make docs-lint` and `make gates`
- [x] 5.2 Record the plan notes in `docs/backlog.md` (the two fixed entries removed, the four widened or corrected, the raised-again Low), checked by `make docs-lint`
- [x] 5.3 Run `make test`, `make lint`, `make diagnose`, `make bench` on `lh` and `j`, `make gates`, and `make spec-validate`, all passing
