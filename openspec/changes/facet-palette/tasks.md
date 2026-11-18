## 1. Palette roles and colors

- [x] 1.1 Add the roles BORDER, PANEL_DIM, and ON_SEARCH to every palette in `carat/domain/themes.rb`, map `FloatBorder` to BORDER and `Search` and `Todo` to ON_SEARCH, proven by "The border colors" and "The search colors" rows in `test/domain_theme.rb`
- [x] 1.2 Set carat-dark and carat-light's SEARCH, carat-light's SELECTION, PANEL_NC, and FLOAT, and carat-dark's PANEL_NC 256 index (`carat/domain/themes.rb`), proven by "The search colors", "The light selection shows", and "The panel colors" rows in `test/domain_theme.rb`
- [x] 1.3 Take Carat's float border out of the 3:1 floor with its 1.3:1 floor in `test/domain_theme.rb` ("The border stays apart from the float", "Every palette passes", "Every palette passes on the cursor line")
- [x] 1.4 Map `StatusLineModeCommand` to CYAN in `GROUPS`, proven by "The command pill is cyan" rows in `test/domain_theme.rb` and the pill rows in `test/adapters_status_bar.rb`

## 2. The current match

- [x] 2.1 Fill the match holding the cursor with `CurSearch` in `FramePresenter#paint_matches` (`carat/adapters/frame_presenter.rb`), proven by "The current match is bold" in `test/adapters_frame_presenter.rb` and "hlsearch draws every match" in `test/editor_search.rb`

## 3. The sparkle

- [x] 3.1 Draw the sparkle in `Title` in `StartArt.from_plain` (`carat/domain/start_art.rb`), proven by the Colors row in `test/editor_start_screen.rb`

## 4. Docs and findings

- [x] 4.1 Update `docs/compatibility.md` (UI groups, search highlighting), checked by `make docs-lint`
- [x] 4.2 Append the plan's backlog entries to `docs/findings/facet-palette.md`
