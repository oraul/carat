# Tasks

## 1. Placement

- [ ] 1.1 `carat/domain/float_window.rb`: add `MARGIN`, the `centered` member, the margin in `place` and `shift`, `text_room(cols, style)`, and no shadowed `edge`; prove it in `test/domain_float_layer.rb` (A float too large for the screen is cut and moved in, A float keeps its margin at the corner, The frame rule, A centered box under both borders, The edge follows the last placement)
- [ ] 1.2 Callers of `text_room` (`follow_palette.rb`, `show_key_hints.rb`, `show_hover.rb`, `show_signature.rb`, `open_definition_float.rb`): drop the border argument; the palette sets `centered`; prove it in `test/editor_palette.rb` (The palette is centered without a border, The palette is centered again after a resize, Without an edge the palette uses the border columns), `test/adapters_hover.rb`, `test/adapters_signature.rb`, `test/adapters_definitions.rb`, `test/editor_key_hints.rb`, and `test/editor_floats.rb` (A float too large for the screen is cut and moved in)

## 2. Notification titles

- [ ] 2.1 `carat/adapters/frame_presenter.rb`: `paint_title` takes the highlight and draws the notice title; the class comment names the floats; prove it in `test/editor_floats.rb` (A notification title is centered like a float title)

## 3. The frame through the plugin API

- [ ] 3.1 `carat/plugin_api.rb` (`FloatFrame`, `Host#float_frame`, 2.6, the `FloatOptions` comment), `carat/use_cases/plugins/plugin_link.rb`, `carat/use_cases/plugins/window_requests.rb`; prove it in `test/editor_floats.rb` (The frame under each border, API version) and `test/domain_plugin_manifest.rb`
- [ ] 3.2 `carat/plugins/finder/plugin.rb`: size the boxes from the frame; prove it in `test/editor_finder.rb` (The finder boxes share an edge, The finder boxes share an edge without a border)

## 4. Offset range check

- [ ] 4.1 `carat/domain/float_spec.rb` (`OFFSET_MAX`, `offset_refusal`, `refusal` with the offsets) and `window_requests.rb` (`open_float`, `move_float`); prove it in `test/domain_float_layer.rb` and `test/editor_floats.rb` (An offset out of range is refused)

## 5. Docs

- [ ] 5.1 `docs/plugins.md` (2.6, `float_frame`, the `open_float` row), `docs/codebase-map.md` (areas 11, 13, 15), `docs/architecture.md` section 9, `README.md` (`winborder`, the finder); run `make docs-lint` and `make gates`
