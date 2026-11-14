# Design

## Context

`FollowPalette#rows` builds each row as `pad(name, 28)`, `pad(key, 12)`, then the description, cut to the float's width; `pad` keeps `width - 1` cells and a space, so a name keeps 27 characters. `filter` scores every entry with `score_of` (the better of the name's and the description's `FuzzyMatch.score`) and keeps only the order. The float is a menu, and `FramePresenter#float_group` fills each row with `Pmenu`, or `PmenuSel` on the selected row; a float whose buffer is `styled?` gets its rows' tokens painted on the float layer, which is how the documentation float colors its markup. `OpenPalette#walk` spells each key with `KeyNotation.format`. `OpenCompletionPopup#rows` writes `" "`, the icon, `" "`, the label, the detail, and `" "`, and its spec's column subtracts that leading space and `FloatWindow::PAD` so the label stands under the typed word.

## Goals / Non-Goals

Goals: every shipped name whole, the three columns aligned with the description dimmed and the key in caret notation, the matched characters marked, the selected row at 4.5:1 at every depth, the popup padded by the float's column only, and the `palette` scenario held.

Non-goals: match spans in the completion popup or the finder, the key hints panel, configurable group colors.

## Decisions

### The row: name, dimmed description, key on the right

`NAME_WIDTH` becomes 30, so a 29-character name and its space fit. The key column of `KEY_WIDTH` 12 stands at the row's right end, and the description takes the cells between, `width - NAME_WIDTH - KEY_WIDTH`; when fewer than two remain the description is left out and the key follows the name, and the row is cut to the width as before. The key is fit to `KEY_WIDTH - 1` cells after a padded description, so a key of wide or combining characters is cut by cells as now. Alternative: keep the key after the name and dim the trailing description; rejected because the acceptance lists the dimmed column between the name and the keys, and a right-hand key column reads as the shortcut column of other editors' palettes.

### Caret notation in the key

`KeyNotation.caret(code)` spells a control code as `^` and the character 64 above it (`^W`, `^@`, `^[` never arises since `<Esc>` is named), and every other code as `format` does; `OpenPalette#walk` uses it, so `palette.keys` holds `^Ws` and `<Space>p`. Only the palette shows these keys, so no other reader changes.

### Stored matches and their spans

`Palette` gains `fields`, parallel to `matches`: 0 when the name's score was used (ties go to the name), 1 for the description. `filter` fills it in the same insertion as `matches`. `FollowPalette#show` gives the scratch buffer one `SyntaxLine` style per row, its tokens a triple each (code point start, length, group): first the description column in `PmenuExtra` (`PmenuExtraSel` on the selected row), then each run of matched characters in `PmenuMatch` (`PmenuMatchSel`). The runs come from `FuzzyMatch.positions(query, text)`, the bytes the score walk matched, turned into code points of the row; a run past the field's kept characters is dropped, so a cut name or description never colors the next column. Spans are computed for the shown rows only (at most 15), when the float is rebuilt, which already happens on every key and selection move. The presenter needs no change: `paint_float_row` paints a styled float's tokens on the float layer, over the row's `Pmenu` or `PmenuSel` fill. Alternative: a span list per match stored by `filter`; rejected, since it allocates for every matching entry on every key while at most 15 rows show.

### Four Pmenu groups and the selected row's contrast

`PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel` are UI groups after `FloatTitle` (ids 52 to 55), so `SYNTAX_FIRST`, `ICON_FIRST`, `MARKUP_FIRST`, and `COUNT` move up by four and a plugin still cannot carry a UI group. Colors: `PmenuMatch` the accent (`BLUE`) on `FLOAT` in bold; `PmenuExtra` `DIM` on `FLOAT`; `PmenuMatchSel` `FG` on `SELECTION` in bold and underline, reverse with bold and underline at 16 colors; `PmenuExtraSel` `FG` on `SELECTION`, reverse at 16 colors. The selected row so keeps `PmenuSel`'s pair at every depth, which `test/domain_theme.rb` checks per group at 24 bits and 256 colors and by the 16-color attribute and colors. Alternative: an accent foreground on the selection; rejected because at 16 colors reverse video turns the accent into the background with the terminal's own color on it, whose contrast no palette controls.

### The popup's padding

`OpenCompletionPopup#rows` drops the leading and trailing space and the spec's column subtracts `icon + 1 + PAD`, so the label still starts under the typed word and the documentation float, placed from the popup's width, keeps its gap.

## Risks / Trade-offs

- Renumbering the syntax, icon, and markup ids changes every id past 51; nothing stores an id across runs, plugins resolve groups by name, and the theme table is keyed by the constants. Mitigation: `test/domain_theme.rb` checks the counts and every group's colors.
- The `palette` scenario rebuilds the styles on each key: at most 15 `SyntaxLine` values and their token arrays per key. Measured with `make bench SCENARIOS=palette` against main at 84467c6: 353.5 allocations per key against 281.0 and a total of 211 us against 201 us per key; the added allocations are the shown rows' token arrays, styles, and match lists, and the name's padded cell is not built twice.
