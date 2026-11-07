# Tasks

## 1. Domain

- [x] 1.1 `carat/domain/float_spec.rb`, `float_window.rb`, `float_layer.rb`: the spec, placement with clamping, the layer by z with its limit and focus index. Tested by `test/domain_float_layer.rb`.
- [x] 1.2 `carat/domain/tab_page.rb` (the layer, `window` answering the focused float, `focus` leaving it) and `tab_list.rb` (`float_tab`). Tested by `test/domain_float_layer.rb`.

## 2. Use cases and keys

- [x] 2.1 `carat/use_cases/windows/open_float.rb` and `close_float.rb`, `carat/use_cases/actions/float_handler.rb` with `float.close` bound to `<Esc>` in normal mode in `config/default.caratrc`, its row in `docs/actions.md`, and the wiring in `EditorAssembly`. Tested by `test/editor_floats.rb`.
- [x] 2.2 `ArrangeView` places floats and scrolls their windows; `FocusWindow`, `CloseWindow`, `Quit`, and `SplitWindow` treat a focused float. Tested by `test/editor_floats.rb`.

## 3. Rendering

- [x] 3.1 `Frame#floats`, `PaintedRows#forget`, and `FramePresenter` painting floats by z with border and title, covered rows compared, segments forgotten on a key change, no scroll under a float. Tested by `test/editor_floats.rb` (frames, dirty rows, no scroll recorded under a float, every frame equal to a full repaint).
- [x] 3.2 `bench/keys.rb` scenario `lh-float` with a 60 by 15 float; `make bench SCENARIOS="lh lh-float"`: `lh-float` 15.0 microseconds and 27 allocations per key against `lh`'s 14.5 and 27.

## 4. Plugin API 2.3

- [x] 4.1 `carat/plugin_api.rb` (`FloatOptions`, `open_float`, `move_float`, `close_float`, 2.3), `PluginLink` overrides, `WindowRequests` requests (a float entered by `focus_window`) and `PluginHost` wiring. Tested by `test/editor_floats.rb` (the requests and refusals), `test/domain_plugin_manifest.rb` and `test/use_cases_plugins.rb` (version rows), `test/adapters_assembly.rb` (the shared tab list), and the link coverage rule of `test/lint.rb`.

## 5. Docs and checks

- [x] 5.1 `docs/codebase-map.md` areas 11, 13, 15, and 18, `docs/plugins.md`, `docs/architecture.md` section 9, `README.md` if a user-visible key changes. Checked by `make docs-lint` and `make lint`.
- [x] 5.2 Run `make gates`, `make spec-validate`, and `openspec validate floating-windows --strict --no-interactive`.
