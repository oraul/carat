# Tasks

## 1. The option and the glyphs

- [x] 1.1 Add `Domain::BorderStyle` (`carat/domain/border_style.rb`) with the five styles and their code points, and `option.winborder` in `carat/domain/options.rb` and `config/default.caratrc` (mirrored by `make gen-config`); prove with rows in `test/domain_options_config.rb` ("The shipped border is rounded", "An unknown border style") and `test/domain_border_style.rb`.

## 2. The box

- [x] 2.1 Give `FloatWindow` (`carat/domain/float_window.rb`) the `edge` member and the padding, set from the option in `ArrangeView#place_floats`; prove with `test/editor_floats.rb` ("Editor-anchored float with a border and a title", "Cursor-anchored float", "A float too large for the screen is cut and moved in", "No border").

## 3. The paint

- [x] 3.1 Add `FloatTitle` to `carat/domain/highlight.rb` and `carat/domain/themes.rb`; prove with `test/domain_theme.rb` ("The UI groups" and the contrast rows).
- [x] 3.2 One border painter in `carat/adapters/frame_presenter.rb` for floats and notices, the padding painted with one fill, and the centered title; prove with `test/editor_floats.rb` ("Padding in NormalFloat", "A centered title", "A long title is cut", "Each border style", "The ASCII border", frames of each style at 40 by 12 and 120 by 36) and `test/editor_completion.rb` ("The selected row spans the padding").

## 4. Callers that size boxes

- [x] 4.1 Size for the padding in `OpenCompletionPopup`, `ShowCompletionDocs`, `FollowPalette`, `ShowKeyHints`, and the finder plugin; prove with `test/editor_completion.rb`, `test/editor_palette.rb`, `test/editor_key_hints.rb`, and `test/editor_finder.rb`, and review every changed snapshot.

## 5. Measure and docs

- [x] 5.1 Add a `palette` bench scenario to `bench/keys.rb`; run `make bench SCENARIOS="lh-float finder palette"` and compare allocations per key and rounds with main's.
- [x] 5.2 Update `README.md` (the option), `docs/codebase-map.md` (the new files), the `FloatOptions` comment in `carat/plugin_api.rb`, and `docs/backlog.md` (the folded entries and the owners of the plan notes).
- [ ] 5.3 Capture the palette, the finder, the key hints, completion with docs, and hover at 120 by 36 as ANSI text from the pseudo-terminal harness into `build/captures/` for the run's report.
