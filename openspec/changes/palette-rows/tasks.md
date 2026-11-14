# Tasks

## 1. Groups and themes

- [x] 1.1 Add `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, `PmenuExtraSel` after `FloatTitle` in `carat/domain/highlight.rb` (later ids up by four) and color them in `carat/domain/themes.rb`; prove with `test/domain_theme.rb` (The UI groups, The selected menu row's groups at each depth)

## 2. Matching and keys

- [x] 2.1 Add `FuzzyMatch.positions` in `carat/domain/fuzzy_match.rb`, the bytes the score walk matched; prove with the FuzzyMatch test
- [x] 2.2 Add `KeyNotation.caret` in `carat/domain/key_notation.rb` and use it in `carat/use_cases/discovery/open_palette.rb`; prove with `test/domain_keys.rb` and `test/editor_palette.rb`

## 3. Palette rows

- [ ] 3.1 Store each match's field in `carat/domain/palette.rb` from `FollowPalette#filter`, and lay rows out as name (30 cells), description, and key on the right in `carat/use_cases/discovery/follow_palette.rb`; prove with `test/editor_palette.rb` (A 29-character name is whole, The key in caret notation on the right, A key of wide characters, A key with combining marks)
- [ ] 3.2 Give the palette buffer one style per shown row with the description and match tokens in the Pmenu groups; prove with `test/editor_palette.rb` (A matched name's letters in PmenuMatch, The selected row's match in PmenuMatchSel, A description match is marked in its column)

## 4. Completion popup

- [ ] 4.1 Drop the rows' own padding spaces and move the column in `carat/use_cases/completion/open_completion_popup.rb`; prove with `test/editor_completion.rb` (A row's cells, The popup pads one column)

## 5. Docs and checks

- [ ] 5.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, and `docs/architecture.md` for the groups and the palette row; run `make bench SCENARIOS=palette`, `make gates`, and `make spec-validate`
