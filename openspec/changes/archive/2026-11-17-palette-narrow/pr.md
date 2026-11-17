fix(palette): keep a row's label at the narrowest palette width

## Summary

Keeps a command palette row's label visible at every float width, leaving out the key's column when the text is narrower than 24 cells instead of letting the key take the whole row. Below about 14 cells of float a row showed only its key, so at the smallest screen the palette could not tell its entries apart.

---

## Changes

- Fix the palette rows so that under 24 cells of text the key is left out and the label takes the row, while at 24 cells and up the layout is unchanged
- Remove the unread cut parameter from FollowPalette's styles, since the cut mark is never styled and the marks' limits do not depend on it
- Change the palette's pad to add the missing spaces in one step instead of one space per loop pass
- Add table-driven cases to test/editor_palette.rb for the smallest screen with and without a border and for texts of 14, 23, and 24 cells
- Document the narrow-width behavior in the README and correct the follow_palette entry of docs/codebase-map.md, which named DisplayWidth.fit
- Update the command-palette spec with the label kept at the smallest screen and archive the palette-narrow change

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking finding and two advisories, the design wording one fixed and the pad simplification dropped as style
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after the archive, 53 items pass

---

## Notes

Between 13 and 23 cells of text a row that showed a cut label and its key now shows the label alone, accepted because on a float that narrow the label is what tells the entries apart and the palette is filtered by name. The pad keeps ljust, whose copy keeps rows from appending into the palette's descriptions.
