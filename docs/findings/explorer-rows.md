### The nerd set's current marker is still a chevron
- Location: `carat/domain/icons.rb` (the nerd `current` glyph, U+F054)
- Why: `docs/design.md` section 5 says no selected row takes a `>` or `›`, but `test/domain_icons.rb` requires every nerd glyph to be a private use code point, and `▎` is not one, so the nerd set keeps its chevron at the explorer's current row.
- Fix: a private use glyph that is a left bar (or a decision that the nerd set's `current` may be `▎`, with the test's rule relaxed for that name).

### The current row's icon loses its file-type color
- Location: `carat/adapters/frame_presenter.rb` (`paint_marked_row`)
- Why: the fill puts the whole row in `PmenuSel`, so the icon cell is drawn in the selection group, not its `DevIcon` group; a cell holds one group and no selection layer exists.
- Fix: a selection layer beside the cursor-line and sidebar layers in `Highlight` and `Themes.from_palette`, so any group keeps its foreground over the selection background.

### The current row's label is not bold
- Location: `carat/adapters/frame_presenter.rb` (`paint_marked_row`)
- Why: `docs/design.md` section 5 gives a selected row a bold label; only the fill and the bar are drawn.
- Fix: also fill the cells after the icon with `PmenuLabelSel`, or fold it into the `one-accent` change that unifies the four selection marks.
