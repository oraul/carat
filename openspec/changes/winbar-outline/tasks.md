## 1. The outline after a restart

- [ ] 1.1 Add `SymbolRequest#forget` (`carat/domain/symbol_request.rb`) and call it from `JsonRpcLanguageGateway#restart`; prove it with the `test/editor_breadcrumbs.rb` row "A restart keeps the new outline".
- [ ] 1.2 Correct `SymbolOutline`'s comment to say names are cut to 40 bytes (`carat/adapters/symbol_outline.rb`).

## 2. One owner of the winbar decision

- [ ] 2.1 Add `TabPage#winbar_with?` as the one comparison of the modes and make `winbar?` use it (`carat/domain/tab_page.rb`); check it in `test/editor_breadcrumbs.rb`.
- [ ] 2.2 Make `SplitWindow#winbar_after?` ask `TabPage#winbar_with?` and add no row when the new window keeps a scratch buffer (`carat/use_cases/windows/split_window.rb`); prove it with the rows "A split count from a scratch window" and "A split from a scratch window to a file has its row".
- [ ] 2.3 Add the `Window#winbar` member (`carat/domain/window.rb`), set it in `ArrangeView` (`carat/use_cases/arrange_view.rb`), and paint from it in `FramePresenter#paint_winbars` (`carat/adapters/frame_presenter.rb`); the existing winbar rows of `test/editor_breadcrumbs.rb` and `test/use_cases_arrange_view.rb` prove the frames are unchanged.

## 3. Docs and checks

- [ ] 3.1 Update `docs/codebase-map.md` for `TabPage`, `Window`, `ArrangeView`, `SplitWindow`, `FramePresenter`, and `SymbolRequest`.
- [ ] 3.2 Run `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the targeted tests.
