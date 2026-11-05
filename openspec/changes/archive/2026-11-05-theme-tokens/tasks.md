# Tasks

## 1. Groups and palettes

- [x] 1.1 `carat/domain/highlight.rb`: the 41 UI groups, the syntax groups from 41, the thirteen file-icon groups from 71, `token?` and `token_id`; `test/domain_theme.rb` rows for the names, ranges, and lookups.
- [x] 1.2 `carat/domain/theme.rb`: the 256-color and 16-color-attribute arrays and `paints_background?`; `carat/domain/themes.rb`: the roles, the group table, the four palettes, the aliases, the backgrounds, `find(name, background)`; `test/domain_theme.rb` rows for the palettes, aliases, backgrounds, and the WCAG AA contrast table.
- [x] 1.3 `carat/domain/options.rb`: the `background` option with its check, `theme` defaulting to `one_dark`; `config/default.caratrc` and the generated mirror; `carat/use_cases/ex/set_command_handler.rb` lists `background` as pending; `test/domain_theme.rb` and `test/domain_options_config.rb` rows.

## 2. Output

- [x] 2.1 `carat/adapters/sgr_table.rb`: the palette's 256-color index and the 16-color attributes; `carat/adapters/screen_presenter.rb`: the Normal sequence before a clear and a scroll when the theme paints the background; `carat/adapters/editor_assembly.rb` passes the background; `test/adapters_screen_presenter.rb` rows for each depth, the 256 override, the 16-color fallback, and the painted background.

## 3. File-icon colors

- [x] 3.1 `carat/use_cases/plugins/ui_requests.rb` and `plugin_syntax.rb` take the file-icon groups; `window_requests.rb` gives a plugin's scratch buffer its filetype; `carat/plugin_api.rb` 2.1; `test/domain_plugin_manifest.rb` and `test/editor_plugins.rb` rows.
- [x] 3.2 `carat/plugins/explorer/`: the `explorer` filetype, the icon groups, `tokenize`; `test/editor_explorer.rb` rows for the icon cells and `:syntax off`.

## 4. Documentation

- [x] 4.1 `docs/compatibility.md` rows for `theme` and `background`, `docs/plugins.md` (2.1, icon groups, scratch filetype), `docs/architecture.md` entities and configuration, the README, `docs/codebase-map.md`, and `docs/backlog.md` (the themes entry narrowed, the backup evidence added).
- [x] 4.2 `make gates`, `make docs-lint`, and the bench figures for `lh`, `j`, and `insert`.
