## 1. The fold model

- [x] 1.1 Add `Domain::Folds` (`carat/domain/folds.rb`): create with nesting, open, close, toggle, delete, eliminate, the closed region at a row, screen-row counting, the shift, and the fold text; proved by `test/domain_folds.rb`
- [x] 1.2 Give `Window` a `folds` member copied by `copy_from` and dropped by `show`, and `Buffer` its `fold_lists` shifted in `splice`; proved by `test/domain_folds.rb` and the put row of `test/editor_folds.rb`

## 2. The keys

- [x] 2.1 Add `OperatorKind::FOLD` and the fold case and linewise widening in `Operate`; proved by `test/editor_folds.rb`
- [x] 2.2 Add `ChangeFolds` and `FoldHandler`, wire them in `EditorAssembly`, bind the keys in `config/default.caratrc` and `make gen-config`; proved by `test/editor_folds.rb` and the `docs/actions.md` drift check of `test/use_cases_actions.rb`
- [x] 2.3 Make `Motions.vertical` pass a closed fold; proved by `test/editor_folds.rb`

## 3. The drawing

- [x] 3.1 Draw a closed fold as one row in `FramePresenter#paint_window`, place the cursor and scroll by screen row (`Window#scroll_to_row`, `ArrangeView`); proved by `test/editor_folds.rb`
- [x] 3.2 Count a closed fold as one row where the screen row is computed: the syntax range ends at `Window#shown_end`, and the completion, documentation, hover, signature, and definition floats and `Layout#neighbour` use `Window#row_offset`; a fold made or deleted drops every kept fold text; proved by `test/editor_folds.rb` (the highlighted line below a fold, the float below a cursor under a fold, showing another buffer) and `test/domain_folds.rb` (the outer fold made after the inner one)
- [x] 3.3 Move a cursor left inside a closed fold (G, gg, a search, a mark) to the fold's first line in `ArrangeView` after every command outside insert and replace modes, as Neovim's foldAdjustCursor does; proved by `test/editor_folds.rb` (a count G into a closed fold, G into a closed fold at the end, the cursor drawn on the fold row)
- [x] 3.4 Open the line of `o` below a closed fold's last line and of `O` above its first in `InsertModeHandler`, as Neovim's n_opencmd does; proved by `test/editor_folds.rb` (o and O on a closed fold, the insert cursor drawn on the row below the fold)

## 4. Docs

- [x] 4.1 Update `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, `docs/architecture.md`, and README.md; `make docs-lint`, `make gates`, `make spec-validate`
