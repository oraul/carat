# Tasks

## 1. The float's own border style

- [ ] 1.1 `carat/domain/float_window.rb` `border_style` and `style_under`, `carat/domain/float_spec.rb` `bordered`, `carat/use_cases/arrange_view.rb` places each float with its own style's edge (proved by "A float border style of none" and "A float opened without a border gets one" in `test/editor_floats.rb`)
- [ ] 1.2 `carat/adapters/frame_presenter.rb` `paint_edge` takes the glyph set, `paint_border_row` draws a float's own style and its ASCII form (proved by "Each float border style", "A float border style in ASCII", "The empty style follows winborder", "A restyled border repaints" in `test/editor_floats.rb`)

## 2. The host request

- [ ] 2.1 `carat/plugin_api.rb` `Host#set_float_border` and API 2.13, `carat/use_cases/plugins/plugin_link.rb` override, `carat/use_cases/plugins/window_requests.rb` `set_float_border` (proved by "Bad border requests are refused" in `test/editor_floats.rb`, "A plugin requests a border style" in `test/use_cases_plugins.rb`, and `make lint`)
- [ ] 2.2 Version tests: `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb` read 2.13 (proved by "A plugin written against 2.10 still loads", "A plugin written against 2.11 still loads", and "A plugin written against 2.12 still loads" in `test/use_cases_plugins.rb`)

## 3. Docs

- [ ] 3.1 `docs/plugins.md` (request row, version history, `api_version`) and `docs/codebase-map.md` (area 15, `FloatWindow`, `FloatSpec`, `FramePresenter`) (proved by `make docs-lint` and `make lint`)
