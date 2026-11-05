# Tasks

## 1. The cursor-line layer of groups

- [x] 1.1 Add `CURSOR_LINE_LAYER`, `LIMIT`, and `base` to `carat/domain/highlight.rb`, resolve the layered ids in `Themes.from_palette` (`carat/domain/themes.rb`), and build their sequences in `carat/adapters/sgr_table.rb`; verified by `test/domain_theme.rb` (contrast of every group on the cursor line, at least 3:1, in each palette at 24 bits and 256 colors, a group with its own background kept) and `test/adapters_screen_presenter.rb` (a layered Comment at 16 colors is underlined)
- [x] 1.2 Add `Frame#lift` in `carat/domain/frame.rb`; verified by `test/domain_frame.rb`

## 2. The cursorline option

- [x] 2.1 Add `cursorline` to `carat/domain/options.rb`, `option.cursorline true` to `config/default.caratrc`, and regenerate `carat/domain/default_config.rb` with `make gen-config`; verified by `test/domain_options_config.rb` rows
- [x] 2.2 Handle `cursorline` and `cul` with the boolean forms in `carat/use_cases/ex/set_command_handler.rb`; verified by table rows in the `:set` test of `test/editor_search.rb` or `test/editor_syntax.rb`

## 3. Painting the cursor line

- [x] 3.1 Add the layer as an input of a segment in `carat/adapters/painted_rows.rb` and paint it in `carat/adapters/frame_presenter.rb` (the current window only, the number in `CursorLineNr`, the visual cursor cell kept on the layer); verified by a table in `test/adapters_frame_presenter.rb` (current window, other window, past the end, option off, after `j`, a selection on the line, the number)
- [x] 3.2 Adapt the tests whose cursor row reads a cell's group under the shipped option; verified by `make test`

## 4. Shapes and the exit paths

- [x] 4.1 Map replace mode to the underline in `FramePresenter#place_cursor`, write `ESC [ 4 q` in `ScreenPresenter#present`, and reset to the terminal's shape in `LEAVE`; verified by a shape table in `test/adapters_frame_presenter.rb` and the byte checks in `test/adapters_screen_presenter.rb` and `test/editor_screen.rb`
- [x] 4.2 Move the screen enter and the file open inside the `begin` of `bin/carat.rb`; verified by `test/smoke_editor.rb` asserting the restore tail after `:q`, `:wq`, closing the last window, `SIGTERM`, and a new `SIGINT` session

## 5. Docs and records

- [x] 5.1 Document the option, `:set cursorline`, and the shapes in `docs/compatibility.md` and `README.md`, the layer in `docs/architecture.md` section 8.2, and the touched areas in `docs/codebase-map.md`; verified by `make docs-lint` and `make gates`
- [x] 5.2 Apply the plan notes to `docs/backlog.md` (the wrap-width entry widened to five comments, the delivered-changes list widened, the spec preview links and the positional `Tree` flag added, the map's Designs lines added to the `architecture-drift` entry); verified by `make docs-lint`
- [x] 5.3 Run `make gates`, `make spec-validate`, and the bench budget; confirm every delta scenario has its test
