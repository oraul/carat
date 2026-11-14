# Proposal

## Why

The command palette's name column holds 27 characters, so the five shipped action names longer than that (`textobject.inner_single_quote` and `textobject.inner_double_quote` at 29 among them) lose their last letters, the typed letters are not shown where they matched, and the row's columns are all drawn in one color. The completion popup pads its rows with a space on each side on top of the float's own padding column, so it alone stands two columns off its text. This is part b of `menu-hints` (sprint 3 item 1 of `docs/queue.md`), a user now-request; it delivers no new roadmap item of `docs/architecture.md` section 12 and refines the palette and popup the roadmap already shipped.

## What Changes

- The palette's row is the name in a 30-cell column (a 29-character name whole), the description in a dimmed column after it, and the first normal-mode key in caret notation (`^Ws` for `<C-w>s`) in a 12-cell column at the row's right end, every column aligned on every row.
- The palette keeps, for each match, whether the name or the description matched (the one the score came from), and draws the matched characters of the shown rows in `PmenuMatch`, `PmenuMatchSel` on the selected row; the description column is drawn in `PmenuExtra`, `PmenuExtraSel` on the selected row.
- Four UI highlight groups with Neovim's names follow `FloatTitle`: `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, `PmenuExtraSel`; every palette colors them, the selected-row groups reaching 4.5:1 at 24 bits and 256 colors and keeping `PmenuSel`'s reverse video at 16 colors.
- `FuzzyMatch.positions` answers the bytes `FuzzyMatch.score` matched, in the same walk.
- The completion popup's rows drop their leading and trailing space: the float's one padding column is the popup's only padding, and the popup moves one column right so its labels stay under the typed word.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-palette`: the row's columns (a 29-character name whole, the dimmed description, the caret-notation key on the right), and the matched characters drawn in the Pmenu match groups.
- `completion`: the row's cells lose their own padding space on each side.
- `color-themes`: four more UI groups, and the selected menu rows' contrast at each color depth.

## Impact

- Code: `carat/use_cases/discovery/follow_palette.rb`, `carat/use_cases/discovery/open_palette.rb`, `carat/domain/palette.rb`, `carat/domain/fuzzy_match.rb`, `carat/domain/key_notation.rb`, `carat/domain/highlight.rb` (the syntax, icon, and markup ids move up by four), `carat/domain/themes.rb`, `carat/use_cases/completion/open_completion_popup.rb`.
- Tests: `test/editor_palette.rb`, `test/editor_completion.rb`, `test/domain_theme.rb`, `test/domain_fuzzy_match.rb` or the test that holds FuzzyMatch, `test/domain_keys.rb` for the caret form.
- Docs: `docs/compatibility.md` (the UI groups), `docs/codebase-map.md` (the palette and highlight lines), `docs/architecture.md` (the UI group count in the `Highlight` line).
- README.md: unchanged, no command, binding, option, or target changes; the palette and popup look different but are reached the same way.
- docs/architecture.md: changed, the `Highlight` line's UI group count and names.
- Bench: `palette` refilters on each key as before; the stored field is one integer per match and the spans are computed for the shown rows only.

Assumptions:

- "A dimmed column" is the description, between the name and the key, as the acceptance lists them; the key column stands at the row's right end.
- Caret notation applies to control keys only (`<C-w>` is `^W`, `<C-@>` is `^@`); named keys keep their Vim spelling (`<F1>`, `<Space>`, `<CR>`).
- A match is drawn in the field it scored in, the name when the name's score is at least the description's; a matched character a column cut hides is not drawn.
- The selected row's match is `PmenuSel`'s colors in bold and underline, and its description `PmenuSel`'s colors, so the selected row's contrast is `PmenuSel`'s at every depth; under `NO_COLOR` the match is not marked, as documentation styles are not.

Out of scope: the key hints panel and the `screen_cols < 6` guard (`discoverability-tidy`), the documentation float's gap beside the popup, match spans in the completion popup and the finder, and user-defined colors for the new groups.
