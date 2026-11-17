feat(themes): draw the status bar's counts and accents readably

## Summary

The status bar's diagnostics counts now draw on the bar's own background, and every accent on the bar, the lsp slot and the counts, reads at 4.5:1 on it at 24-bit, 256, and 16 colors. At 16 colors the lsp accents dark yellow and green read near 1.5:1 on the light gray bar, and the counts drew on the terminal's background, leaving a hole in the bar. Four count groups take accents picked per palette, and at 16 colors the accents fall back to the colors that read on the bar under xterm's default colors.

---

## Changes

- Add the UI groups StatusLineDiagnosticError, StatusLineDiagnosticWarn, StatusLineDiagnosticInfo, and StatusLineDiagnosticHint after StatusLineLspError, drawn over the bar's background at every depth, so the editor knows 60 UI groups and the syntax, file-icon, and markup ids move up by four.
- Change the status bar to draw its diagnostics counts and the segment's closing space in the count groups instead of the terminal's background.
- Change the 16-color accents of StatusLine, the lsp groups, and the count groups so each reaches 4.5:1 on the bar under xterm's default colors, on the light gray bar and on the blue bar of dark_plus and light_plus.
- Add the palette roles PANEL_BLUE and PANEL_CYAN for the info and hint counts, error and warning sharing the lsp slot's red and yellow bar accents.
- Add tests in test/domain_theme.rb that the count groups follow the lsp groups, pass contrast on the bar, share its background, and that the bar reads at 16 colors, and update the status bar test for the new groups.
- Update the color-themes and status-bar specs, and document the new groups in the README, the architecture, the codebase map, and the compatibility table.

---

## Testing

- Run the security review of the committed diff, passing with no High, Medium, or Low finding.
- Run the quality review, passing with no blocking finding and three advisories.
- Run the check stages docs-lint, dev-build, test-build, diagnose, test-run, bench-budget, tools-test, gates, and metrics, all pass.
- Run the benchmark review against main's recorded figures, passing with no blocking finding.
- Run make spec-validate after the archive, all 53 items pass.
- Run make gates and make docs-lint on the packaged branch, all pass.

---

## Notes

Plugins resolve highlight groups by name, so the shifted ids of the syntax, file-icon, and markup groups break no plugin. At 16 colors some accents give up their hue for the bar's own text color, since no other basic color reads there; the slot's text and the count's icon still tell the states apart. The 16-color contrast of groups off the bar is left out of scope. The three quality advisories on test/domain_theme.rb, a magic group offset, an assertion over the test's own color table, and a comment wrap, are style-level and dropped from this change rather than edit the reviewed test after its reviews.
