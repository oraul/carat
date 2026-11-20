# Tasks

## 1. Groups and the float's style count

- [x] 1.1 `carat/domain/highlight.rb` `float_style?` and `float_style_id`, `token?` unchanged (proved by "Other UI groups are refused" in `test/editor_floats.rb` and `test/domain_theme.rb`)
- [x] 1.2 `carat/domain/float_window.rb` `style_count`, `carat/adapters/frame_presenter.rb` float key with the count, `FLOAT_STRIDE` 11 (proved by "A restyle repaints" in `test/editor_floats.rb`)

## 2. The host request

- [x] 2.1 `carat/plugin_api.rb` `Host#style_float` and API 2.12, `carat/use_cases/plugins/plugin_link.rb` override, `carat/use_cases/plugins/window_requests.rb` `style_float`, `set_float_lines` dropping the style (proved by "A row and spans styled", "Spans without a selected row", "An empty style clears it", "Bad rows and spans are refused", "Another plugin's float is not styled", "A refill drops the style" in `test/editor_floats.rb`, and `make lint`)
- [x] 2.2 `carat/use_cases/plugins/ui_requests.rb` `syntax_group` resolves `PmenuSel` and `PmenuMatch` (proved by "The popup menu groups resolve" in `test/use_cases_plugin_syntax.rb`)
- [x] 2.3 Version tests: `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb` read 2.12 (proved by "A plugin written against 2.10 still loads" and "A plugin written against 2.11 still loads" in `test/use_cases_plugins.rb`)

## 3. Docs

- [x] 3.1 `docs/plugins.md` (request rows, version history, `api_version`) and `docs/codebase-map.md` (area 15, `Highlight`, `FloatWindow`) (proved by `make docs-lint` and `make lint`)

## 4. Fix round

- [x] 4.1 `carat/use_cases/plugins/window_requests.rb` `set_float_lines` drops the style only when the buffer is styled, so a refill of an unstyled float allocates no array and grep's allocations per key are back at main's (proved by `make metrics SCENARIOS=grep` and "A refill drops the style" in `test/editor_floats.rb`)
- [x] 4.2 `carat/use_cases/plugins/window_requests.rb` private `unlisted_float_tab` and `float_in` hold the lookup `set_float_lines` and `style_float` shared, with no nullable local so the runner stays at 2 re-narrowing rounds, and the `row_styles` comment is reflowed (proved by `test/editor_floats.rb`)
- [x] 4.3 `carat/domain/highlight.rb` keeps PmenuSel and PmenuMatch in one private `FLOAT_GROUPS` both `float_style?` and `float_style_id` read (proved by "Other UI groups are refused" in `test/editor_floats.rb` and "The popup menu groups resolve" in `test/use_cases_plugin_syntax.rb`)
- [x] 4.4 `test/use_cases_plugins.rb` styles a float through a disabled plugin's link and reads the refusal and the unchanged style
