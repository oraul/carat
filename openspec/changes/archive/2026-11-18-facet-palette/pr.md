feat(theme): give the carat palettes the facet colors and a bold current match

## Summary

Gives Carat's dark and light palettes the Facet plan's colors for the float border, the search tint, the light selection and panels, and the 256-color panels, draws the match under the cursor bold in CurSearch, turns the command pill cyan, and draws the start sparkle in sapphire. The float border competed with float text, light Search and Selection barely showed on the light background, the current match differed from the others by nothing, and at 256 colors carat-dark's panels merged with the background.

---

## Changes

- Add the BORDER and ON_SEARCH palette roles in every palette, following the guide-colors pattern, with FloatBorder drawn in BORDER and Search and Todo text in ON_SEARCH, the other four palettes keeping their look
- Change carat-dark and carat-light SEARCH to a soft tint (#4a4129 and #f7e3a1) and take their float border out of the 3:1 decoration floor with a 1.3:1 floor against the float background
- Add CurSearch painting in the frame presenter, so the match holding each window's cursor is drawn in the strong orange, bold, while hlsearch shows the matches
- Change carat-light SELECTION to #c2ccef (1.54:1 on the background, was 1.26:1) and its PANEL_NC and FLOAT to #eceef3
- Pin carat-dark's PANEL_NC to index 233 at 256 colors, apart from the background's 234
- Change StatusLineModeCommand, the pill of the command line and of every query picker, to cyan in every palette
- Change the start screen sparkle to the Title group, sapphire in Carat's palettes
- Add theme rows pinning each new value on both palettes, frame presenter rows for the bold current match in two windows, and search and start screen rows
- Document the colors and the current match in README.md and docs/compatibility.md, and sync the color-themes, search, and start-screen specs from the archived change

---

## Testing

- Run the security review of the committed diff at ba74b65, passed with no findings (high 0, medium 0, low 0, blocking 0)
- Run the quality review at ba74b65, passed with 0 blocking and 0 advisory findings after the earlier advisories were fixed
- Run the checker stages at ba74b65 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark review at ba74b65, passed with no blocking finding
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

The brief's match count on the command line (Neovim's searchcount, [3/12]) is split off by the plan as search-count, so this pull request draws the bold current match but not the count. The brief's PANEL_DIM role is left out, since no group draws it yet; ui-groups adds it with the status bar's dim text group. The light search tint is 1.23:1 on the background, below the old 1.31:1, by the plan's choice of a soft tint with a strong current match. A Low security finding in groom's duplicate guard, which reached the branch through the merge of main, is recorded in docs/findings/facet-palette.md.
