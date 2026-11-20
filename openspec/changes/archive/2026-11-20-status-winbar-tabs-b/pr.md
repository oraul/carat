feat(ui): give the buffer tabs and the winbar the facet look

## Summary

Gives the buffer tabs and the winbar the Facet look: the selected tab is led by a gem and every tab ends in a thin separator, and the winbar is dimmed except for the current window's innermost name in the accent. Before this the selected tab differed from the others by color alone, tabs ran together, and a winbar was one block in the accent, so the tab line and the status bar did not speak one language.

---

## Changes

- Change the buffer tabs so the current window's tab starts with the gem `◆` (`*` under `option.icons ascii`) in `TabLineSel` and every tab ends in a thin `│` (`|` under ascii) in `TabLine`, a tab growing by two cells while the modified mark keeps its one fixed cell
- Change the winbar to draw its space, path, separators, outer symbols, and pad in the quiet `TabLine`, with only the current window's last name, the innermost symbol spanning the cursor row or else the path, in the `TabLineSel` accent, found in one pass without allocating
- Add tab bar tests for the gem, the separator, and the three icon sets, and update the tab, tab flow, frame presenter, and definitions tests for the wider tabs and their recomputed overflow rows
- Add a breadcrumbs test that only the innermost symbol of the current window's winbar takes the accent
- Change the buffer-tabs and breadcrumbs specs to the new cells and groups
- Document the look in README.md, docs/compatibility.md, and docs/codebase-map.md
- Record the plan, the metrics history row, and the open advisories of the run

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the quality review, pass with no blocking finding and one advisory, recorded in docs/findings/status-winbar-tabs-b.md
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark review against main's recorded figures, pass with no blocking finding
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

Both rows still read the one no-name word and add no highlight group: the accent is the mode pill's `TabLineSel`, whose contrast and bold at 16 colors and under NO_COLOR the theme tests already check. The winbar keeps its thin separator and its ascii form. Neovim's `option.showtabline` is left out of this change and queued on its own as `showtabline`. A tab is two cells wider, so fewer tabs fit before the overflow counts.
