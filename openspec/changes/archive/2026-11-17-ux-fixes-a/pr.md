fix(ui): close the status bar, finder, and palette ux-pass findings

## Summary

Draws the language server's status segment on the status bar's background in every theme, keeps the finder open on its query when Enter finds no match, and leads each palette row with its readable label, the dotted name second and a cut marked. These were ux-pass findings 3, 5, and 10, which the user asked to fix in Sprint 11: a hole in the one-colored bar, a typo that cost the whole finder query, and palette rows that led with internal names and cut descriptions mid-word.

---

## Changes

- Change the three lsp status groups to the status bar's background in all six palettes, with new PANEL_YELLOW, PANEL_GREEN, and PANEL_RED accent roles picked per palette to read on the bar, so the progress bar's done cells follow
- Fix Enter on a finder showing No match, which now reopens the prompt on the typed text and opens nothing instead of closing and dropping the query
- Change each palette row to show the description first, the dotted name second in a 30-cell column drawn in PmenuExtra, and the key on the right, a cut text ending in an ellipsis or a greater-than sign under the ascii icons, and the name left out first on a narrow palette
- Add theme tests that check every lsp group sits on the bar's background, a finder test for Enter with no match, and palette tests for the row layout, the cut mark, and the narrow case, with their snapshots
- Document the finder's Enter, the palette row, and the status bar's colors in README.md, docs/compatibility.md, and docs/codebase-map.md
- Archive the OpenSpec change, updating the color-themes, file-finder, and command-palette specs

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the quality review, pass with no blocking finding and five advisories
- Run the benchmark against main's recorded figures, pass with allocations held
- Run make spec-validate after the archive, 53 items pass

---

## Notes

The ProcessPort row of docs/architecture.md still names capture(argv) although the port takes an environment since #160; it is recorded in the change's findings, since this change does not edit that document. Of the review advisories, the 16-color contrast of the lsp accents, the diagnostics counts' background on the bar, the palette's per-pass padding, and the codebase map's follow_palette entry, which still names DisplayWidth.fit, are recorded as findings, and the finder's reopen inside a guard condition, a style point, is dropped. The order of the unfiltered palette list and the other ux-pass findings are left out of scope.
