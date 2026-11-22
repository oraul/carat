feat(folds): paint the closed fold row in the Folded group

## Summary

Draws a closed fold's row in its own `Folded` highlight group, the dim role with no background, in every palette, at every color depth, under `option.icons ascii`, and under `NO_COLOR`. The row was painted in `Normal`, so a closed fold read as one more line of text instead of the quiet fold row `docs/design.md` describes, and `docs/compatibility.md` listed the missing `Folded` group as a difference from Neovim.

---

## Changes

- Change the closed-fold branch of the frame presenter to paint the fold row's text and fill in `Folded`, keeping the gutter's line number and sign groups and taking the cursor-line layer of `Folded` on the cursor line.
- Add Neovim's `Folded` group as the last UI group after `MsgDim`, moving the syntax, file-icon, and markup ids up by one.
- Give `Folded` a row in each shipped palette: the dim foreground at 24 bits, 256 colors, and 16 colors (basic color 8), no background, no attributes.
- Add frame presenter tests for the fold row in both carat themes, at 16 colors, under ascii icons, under `NO_COLOR`, and on the cursor line, and a theme test for the `Folded` row of every palette, updating the snapshots that pin a group id by number.
- Add the `folds` and `color-themes` requirements for the `Folded` row to the specs, archived with the change.
- Document the group in README.md, the `Highlight` paragraph of `docs/architecture.md`, the fold rows and UI group count of `docs/compatibility.md`, and the code map.
- Record the plan's feature queue, this lane's metrics row, and the findings left open, among them the fold label's glyphs that differ from the design.

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding
- Run the check stages at the implementation head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark comparison against main's recorded figures, passed with no blocking difference
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

The fold label's text and glyphs stay as they are: `docs/design.md` describes a chevron and a dim line count, while the label is Neovim's `+--N lines: text` filled with a middle dot, also in the ascii set; the brief asks only for the theme group, so that gap is recorded in `docs/findings/folded-row.md` for a later change. A search match on the label is still drawn over the fold row's group, as it was over `Normal`.
