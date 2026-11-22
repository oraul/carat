# Proposal

## Why

A closed fold's row is painted in `Normal` today (`carat/adapters/frame_presenter.rb`, the closed-fold branch of `paint_window`), so it reads as one more line of text, not as the quiet, dim fold row `docs/design.md` section 4 describes (a closed fold's count dim, its gap faint), and `docs/compatibility.md` lists "a fold row has the normal colors, no `Folded` group" as a difference from Neovim. The change is Facet wave 2 work from the feature queue (the user's request), outside the numbered roadmap of `docs/architecture.md` section 12.

## What Changes

- Add Neovim's `Folded` highlight group, the last UI group after `MsgDim`, moving the syntax, file-icon, and markup ids up by one.
- Give `Folded` a row in every palette: the dim role, no background of its own, no attributes, so it shows at 24 bits, at 256 colors, and at 16 colors (basic color 8 in every shipped palette), and on the cursor line over `CursorLine`'s background.
- Paint the whole text of a closed fold's row (its label and its fill) in `Folded`; the gutter keeps its line number and sign groups, and the row on the cursor line takes the cursor-line layer of `Folded` as any other group does. Under `NO_COLOR` the row keeps the group, as the message row does, and under `option.icons ascii` too.

Out of scope: the fold label's text and glyphs. `docs/design.md` describes a faint `▸` chevron and a dim `⋯ 12 lines` count, while `carat/domain/folds.rb` builds Neovim's `+--N lines: text` label filled with `·`; the brief asks only for the theme group, so the label stays as it is and the gap is recorded in the findings file (also the `·` fill drawn in the ascii set). `foldtext`, `fillchars`, and a `FoldColumn` stay out.

Assumptions: the fold row's look is the dim role with no background, as `MsgDim` and the design's "dim" count; the group is a UI group, so a plugin token or a float span cannot carry it, as with every other UI group; a search match on the label is still drawn over `Folded`, as before over `Normal`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `folds`: a closed fold's row is drawn in the `Folded` group.
- `color-themes`: the new `Folded` group's row in every palette.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`.
- Tests: `test/adapters_frame_presenter.rb` (and its snapshot), `test/domain_theme.rb` (and its snapshot), and any test pinning a syntax, icon, or markup id by number.
- Docs: `docs/compatibility.md` (the fold differences and the UI group count), `docs/codebase-map.md` areas 13 and 14, `docs/design.md` unchanged (its section 7 lists no fold row).
- README.md: changed, the fold sentence names the `Folded` group.
- docs/architecture.md: changed, the UI group count of the `Highlight` paragraph.
