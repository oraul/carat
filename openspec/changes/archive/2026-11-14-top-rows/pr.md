feat(tabs): draw the selected tab on the accent with a one-cell mark

## Summary

Draws the selected buffer tab, the current tab-page number, and the current window's winbar as a bold block on the palette's blue accent, keeps the modified mark to one cell, and joins the winbar symbols with a single angle quote. The selected tab was told from the others mostly by a faint color step, about 1.1:1 in one_dark, so users did not notice the tabs at all. This is the first part of the split of the top-rows queue item; the rest is queued as winbar-outline.

---

## Changes

- Change TabLineSel in every palette to bold text-on-accent over the blue accent, at 3:1 or more in background contrast against TabLine and TabLineFill at 24 bits and 256 colors, with a different 16-color background, and bold at every depth so it never relies on color alone
- Change the selected tab's icon to draw in TabLineSel instead of its file-icon group so the accent block is unbroken
- Change the modified mark to take exactly one cell so a tab's width no longer depends on whether its buffer is modified, falling back to the ASCII mark for a glyph measured wider
- Change the winbar to join the path and the symbols with a single angle quote, and with its ASCII form under option.icons ascii
- Refactor the digit fit into the one Frame#put_digits_within used by the tab bar and the status bar, removing TabBar#put_number and StatusBar#digits_within
- Add tests for the accent contrast and bold, the selected tab's icon group, the modified mark's width, the winbar separators, and the digit fit, with their snapshots
- Document the accent tabs and the winbar separator in the README, the code map, and the synced buffer-tabs, breadcrumbs, and color-themes specs

---

## Testing

- Run the security review of the committed diff, passed with no findings: high 0, medium 0, low 0
- Run the checker's fast stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, passed with no blocking finding and five advisories recorded in the backlog
- Run the benchmark review against main's recorded figures, passed with no blocking finding
- Run make spec-validate after the archive, all 51 items pass

---

## Notes

The slot header row's shown view also uses TabLineSel and so shares the accent; the quality review flagged that it is not named in the docs, and it is recorded in the backlog with the other four advisories. The stale outline after LspRestart, the single owner of winbar rows, the scratch-split winbar row, and the SymbolOutline comment are left for winbar-outline.
