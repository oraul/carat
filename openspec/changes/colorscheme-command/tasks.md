# Tasks

## 1. Live palette switch

- [x] 1.1 Add `ScreenPresenter#use_theme(name, background)` (carat/adapters/screen_presenter.rb): rebuild the `SgrTable` at the kept depth and drop the last frame when the name or background differs; call it from `EditorAssembly#render` (carat/adapters/editor_assembly.rb). Proved by test/adapters_screen_presenter.rb ("Switching at 16 colors", 256 colors, unchanged palette writes no clear).

## 2. :set theme and background

- [x] 2.1 Add `theme` and `background` (`bg`) to `SetCommandHandler::NAMES` and drop `PENDING` (carat/use_cases/ex/set_command_handler.rb), its comment updated. Proved by test/editor_set_options.rb (word rows, "Setting the theme and the background", "A theme the configuration refuses", the `:set all` count) and test/editor_syntax.rb (the dropped Not implemented scenario).

## 3. :colorscheme

- [x] 3.1 Add `ColorschemeCommandHandler` (`colo[rscheme]`, carat/use_cases/ex/colorscheme_command_handler.rb) registered after `:set`, with its compatibility row. Proved by test/editor_colorscheme.rb (each shipped name repainting every group, unknown name, no name, both `:set` forms) and test/use_cases_ex.rb (every documented spelling).
- [x] 3.2 Complete palette names after `:colorscheme` in `CompleteCommandLine` (carat/use_cases/complete_command_line.rb). Proved by test/editor_cmdline_complete.rb.

## 4. Docs

- [x] 4.1 Update docs/compatibility.md (the `:colo[rscheme]` row, the `:set` rows, the syntax and Themes paragraphs, the `:set` Differences), README.md, docs/architecture.md (roadmap item 9, `ScreenPresenter`, `SgrTable`), and docs/codebase-map.md (new files, changed lines, area 14 Rules). Proved by make docs-lint, test/lint.rb, test/use_cases_ex.rb.

## Quality review

- [x] 5.1 docs/architecture.md roadmap item 9 credited `:colorscheme` to `set-options` alone; reworded to `set-options` and its parts (fixed).
- [x] 5.2 carat/use_cases/complete_command_line.rb named the command `"colorscheme"` as a bare literal beside the `PATH_COMMANDS` table; moved to a `THEME_COMMANDS` table of the same shape, proved by test/editor_cmdline_complete.rb (fixed).
- [x] 5.3 docs/codebase-map.md's `EditorAssembly#render` line did not name the `use_theme` step it now takes; added (fixed).
- [x] 5.4 docs/compatibility.md's `<Tab>` row and completion Differences and the README's command-line paragraph did not name the palette names after `:colorscheme`; added (fixed).
