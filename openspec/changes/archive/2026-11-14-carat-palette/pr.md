feat(theme): add the carat palettes and 4.5:1 cursor-line text

## Summary

Adds Carat's own palettes, carat-dark and carat-light with a sapphire accent, makes carat-dark the default theme, and holds every text group on the cursor line to 4.5:1 in all six palettes. Carat shipped only other editors' palettes, with carat-dark and carat-light as mere aliases, and in every palette some text drawn on the cursor line fell below 4.5:1.

---

## Changes

- Add carat-dark and carat-light as full palettes, replacing the alias table, and make carat-dark the default in Themes::DEFAULT, the shipped option.theme line, and the fallback for an unknown theme name
- Change one_dark's purple, dark_plus's cursor line and red, and the light palettes' 256-color green so every text group on the cursor line reaches 4.5:1 and every decoration group 3:1, at 24 bits and at 256 colors
- Rename the theme build's 16-color background index lit16 to line_bg16 so it is not named like a group id
- Change the theme, option, and screen presenter tests for the six palettes, the cursor-line contrast tables, and the new default
- Document the six palettes and the default in the README, docs/architecture.md, docs/compatibility.md, and the code map, and correct the UI group count to 56
- Update the color-themes spec for the shipped palettes, the default, and the cursor-line contrast, and archive the change

---

## Testing

- Run the security review of the committed diff, pass with no findings
- Run the quality review, pass with no blocking finding and four advisories recorded in docs/backlog.md
- Run the benchmark comparison against main, pass
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run make spec-validate after the archive, all 51 specs pass

---

## Notes

The cursor line under option.background terminal is left for the queued follow-up carat-palette-b. Two screen presenter scenarios still name one_dark and carat-dark against rows that now draw the other palette; the fix is recorded in docs/backlog.md.
