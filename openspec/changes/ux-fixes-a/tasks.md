## 1. The lsp slot on the bar

- [x] 1.1 Add the roles `PANEL_YELLOW`, `PANEL_GREEN`, `PANEL_RED` to `Carat::Domain::Themes`, give them in the six palettes, and name them with `PANEL` for the three `StatusLineLsp*` groups, proved by `test/domain_theme.rb` "The lsp groups share the bar's background" and "Every palette's lsp groups pass on the bar"

## 2. The finder keeps a query with no match

- [x] 2.1 `Carat::Plugins::Finder::Plugin#on_input` reopens its live prompt on the typed text when Enter comes with no match, proved by `test/editor_finder.rb` "Enter with no match keeps the finder open" and "The query is kept for a correction"

## 3. The palette row

- [x] 3.1 `Carat::UseCases::FollowPalette#rows` and `#styles` lay out the label, the name in `PmenuExtra`, and the key, with a marked cut and the name left out when narrow, proved by `test/editor_palette.rb` "The label first, the key in caret notation on the right", "A cut description is marked", "An ascii cut mark", "A narrow palette leaves the name out", "A 29-character name is whole", "A key of wide characters", "A key with combining marks", "A row leads with its label and fits its columns by display cells", and the three scenarios of "Matched characters are marked"

## 4. Docs and checks

- [ ] 4.1 Update README.md (the finder's Enter, the palette row, the status bar's colors), checked by `make docs-lint`; append the handed ProcessPort finding to `docs/findings/ux-fixes-a.md`
- [ ] 4.2 Run `make gates`, `make spec-validate`, and the touched tests through `make test-one`; hold the recorded allocations with `make bench`
