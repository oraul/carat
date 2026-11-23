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

## test/smoke_editor.rb: intermittent snapshot mismatch under the check's parallel load

- Location: `test/smoke_editor.rb`, the PTY sessions that wait with `settle` for a fixed time before asserting on the drawn bytes (the tree check among them).
- Why it matters: one check run failed `smoke_editor.rb` (first exit 1, then exit 0 with differing output) while the same test passed alone, with the dev binary, under eight busy loops, and in the next full check at the same commit; a timing-dependent assertion can fail a merge for no change in behavior. The failing output was not kept, since the check's clone removes it, so the failing line is unknown.
- Fix outline: make `settle` wait until the output stops growing or a deadline passes, rather than a fixed time, and have `run_tests.sh` print `diff -a` so a binary-looking snapshot difference shows its lines.
