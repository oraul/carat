# Tasks

## 1. The host request

- [x] 1.1 `carat/plugin_api.rb` `Host#set_float_lines` and API 2.11, `carat/use_cases/plugins/plugin_link.rb` override, `carat/use_cases/plugins/window_requests.rb` `set_float_lines`, `carat/domain/float_spec.rb` `titled` (proved by "Refilled in place", "The current float refilled with 0", "Refilled with no lines", "Another plugin's float is not refilled" in `test/editor_floats.rb`, "a float refilled during a selection in it", and `make lint`)
- [x] 1.2 Version tests: `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb` read 2.11 (proved by "A plugin written against 2.10 still loads" in `test/use_cases_plugins.rb`)

## 2. The finder

- [x] 2.1 `carat/plugins/finder/plugin.rb` `refresh` refills its floats while their box is unchanged (proved by "Typing keeps the list float", "Moving the highlight keeps both floats", "The preview closes and returns", "A resize opens the floats at the new size" in `test/editor_finder.rb`, and the unchanged rows there)

## 3. Docs

- [x] 3.1 `docs/plugins.md` (request row, version history, `api_version`, the finder's floats) and `docs/codebase-map.md` area 15 (proved by `make docs-lint` and `make lint`)

## 4. Review fixes

- [x] 4.1 `carat/use_cases/plugins/window_requests.rb` `set_float_lines` refuses with "No float N" a float switched to a listed buffer, such as one of the plugin's scratch buffers, and `docs/plugins.md` and `carat/plugin_api.rb` say so (proved by "A float showing a scratch buffer is not refilled" in `test/editor_floats.rb`)
- [x] 4.2 `carat/plugins/finder/plugin.rb` closes the preview through one private `close_preview`, used by `refresh` and `close_floats` (proved by the unchanged rows of `test/editor_finder.rb`)
- [x] 4.3 `docs/codebase-map.md` names `FloatSpec#titled` (proved by `make docs-lint`)
