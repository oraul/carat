# Tasks

## 1. Live palette switch

- [ ] 1.1 Add `ScreenPresenter#use_theme(name, background)` (carat/adapters/screen_presenter.rb): rebuild the `SgrTable` at the kept depth and drop the last frame when the name or background differs; call it from `EditorAssembly#render` (carat/adapters/editor_assembly.rb). Proved by test/adapters_screen_presenter.rb ("Switching at 16 colors", 256 colors, unchanged palette writes no clear).

## 2. :set theme and background

- [ ] 2.1 Add `theme` and `background` (`bg`) to `SetCommandHandler::NAMES` and drop `PENDING` (carat/use_cases/ex/set_command_handler.rb), its comment updated. Proved by test/editor_set_options.rb (word rows, "Setting the theme and the background", "A theme the configuration refuses", the `:set all` count) and test/editor_syntax.rb (the dropped Not implemented scenario).

## 3. :colorscheme

- [ ] 3.1 Add `ColorschemeCommandHandler` (`colo[rscheme]`, carat/use_cases/ex/colorscheme_command_handler.rb) registered after `:set`, with its compatibility row. Proved by test/editor_colorscheme.rb (each shipped name repainting every group, unknown name, no name, both `:set` forms) and test/use_cases_ex.rb (every documented spelling).
- [ ] 3.2 Complete palette names after `:colorscheme` in `CompleteCommandLine` (carat/use_cases/complete_command_line.rb). Proved by test/editor_cmdline_complete.rb.

## 4. Docs

- [ ] 4.1 Update docs/compatibility.md (the `:colo[rscheme]` row, the `:set` rows, the syntax and Themes paragraphs, the `:set` Differences), README.md, docs/architecture.md (roadmap item 9, `ScreenPresenter`, `SgrTable`), and docs/codebase-map.md (new files, changed lines, area 14 Rules). Proved by make docs-lint, test/lint.rb, test/use_cases_ex.rb.
