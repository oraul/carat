# Tasks

## 1. The frame rule

- [x] 1.1 Add `FloatWindow.frame_width` and `FloatWindow.text_room` in `carat/domain/float_window.rb` and cut `place` with `frame_width`; prove "The frame rule" in `test/domain_float_layer.rb`, `make test-one T=test/domain_float_layer.rb`

## 2. The core floats

- [x] 2.1 Size the palette by `text_room` in `carat/use_cases/discovery/follow_palette.rb`; prove "The palette keeps its right border while the filter shrinks" and "Without an edge the palette uses the border columns" with frame checks in `test/editor_palette.rb`
- [x] 2.2 Size the documentation float by `text_room` in `carat/use_cases/docs/show_hover.rb`; prove "An 80-column hover row shows its last word" in `test/adapters_hover.rb`
- [x] 2.3 Size the signature and the definition float by `text_room` in `carat/use_cases/docs/show_signature.rb` and `carat/use_cases/definitions/open_definition_float.rb`; prove "The signature and the peek fit a narrow screen" in `test/adapters_signature.rb` and `test/adapters_definitions.rb`
- [x] 2.4 Size the key hints by `text_room` in `carat/use_cases/discovery/show_key_hints.rb`; `make test-one T=test/editor_key_hints.rb` (or the key hints test) still passes

## 3. The finder

- [x] 3.1 Name the finder's margin and box frame in `carat/plugins/finder/plugin.rb` and lay the boxes out from them; prove "The finder boxes share an edge" and "The finder boxes keep a gap without an edge" in `test/editor_finder.rb`

## 4. Docs and checks

- [ ] 4.1 Update the `winborder` sentence of `README.md`; `make docs-lint` passes
- [ ] 4.2 Run `make lint`, `make gates`, and `make spec-validate`, all pass
