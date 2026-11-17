## 1. The fold model

- [ ] 1.1 Add `Domain::Folds` (`carat/domain/folds.rb`): create with nesting, open, close, toggle, delete, eliminate, the closed region at a row, screen-row counting, the shift, and the fold text; proved by `test/domain_folds.rb`
- [ ] 1.2 Give `Window` a `folds` member copied by `copy_from` and dropped by `show`, and `Buffer` its `fold_lists` shifted in `splice`; proved by `test/domain_folds.rb` and the put row of `test/editor_folds.rb`

## 2. The keys

- [ ] 2.1 Add `OperatorKind::FOLD` and the fold case and linewise widening in `Operate`; proved by `test/editor_folds.rb`
- [ ] 2.2 Add `ChangeFolds` and `FoldHandler`, wire them in `EditorAssembly`, bind the keys in `config/default.caratrc` and `make gen-config`; proved by `test/editor_folds.rb` and `test/use_cases_actions.rb`
- [ ] 2.3 Make `Motions.vertical` pass a closed fold; proved by `test/editor_folds.rb`

## 3. The drawing

- [ ] 3.1 Draw a closed fold as one row in `FramePresenter#paint_window`, place the cursor and scroll by screen row (`Window#scroll_to_row`, `ArrangeView`); proved by `test/editor_folds.rb`

## 4. Docs

- [ ] 4.1 Update `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, `docs/architecture.md`, and README.md; `make docs-lint`, `make gates`, `make spec-validate`
