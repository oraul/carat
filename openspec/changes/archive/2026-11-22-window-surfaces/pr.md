feat(render): draw sidebars on a darker surface without a separator glyph

## Summary

Draws the sidebar on a darker background with no separator glyph where it meets the editor, and keeps a quiet `│` only between two windows of the same color. The decided design draws no glyph where two surfaces meet, but the explorer was painted like the editor and cut off by a faint separator column.

---

## Changes

- Add a sidebar layer of highlight groups that sits on the darker panel background, and paint every fixed-width window's rows on it, the cursor row keeping its own layer.
- Draw the column between a sidebar and the editor as a blank cell of the sidebar layer, so no separator glyph appears there, while two editor windows side by side keep `│` (`|` with ascii icons).
- Keep the glyph at the sidebar's edge under NO_COLOR and at 16 colors, where a background change cannot show it, through a new `basic_colors=` setting on the frame presenter.
- Change the `WinSeparator` group from the faint tone to the `BORDER` role, and let the cursor-line lift apply only to a plain group's cell.
- Make `Layout#sidebar?` public for the presenter.
- Update the screen-rendering and color-themes specs, and document the fallback edge in design.md, architecture.md, compatibility.md, the code map, and README.md.
- Add tests for the sidebar layer, the edge in each color mode, and the sidebar's cursor row, and update the explorer and tab-flow expectations and snapshots, whose sidebar rows no longer carry a separator.

---

## Testing

- Security review of the committed diff, pass with no High, Medium, or Low findings
- Run the fast stages through the check at the implement commit (docs-lint, dev-build, test-build, test-run, gates, tools-test, diagnose, bench-budget, metrics), all pass
- Benchmark review against main's recorded figures, pass with no blocking finding
- Run `make spec-validate` after the archive, 56 items pass

---

## Notes

The bottom panel stays on the normal background with its separator row, since the request names the sidebar; the follow-up is recorded in the findings file. At 16 colors the edge stays a glyph because the basic set has no background that keeps every text color readable on both dark and light themes.
