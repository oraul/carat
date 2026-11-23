feat(tabs): mark the current tab in bold, not an accent fill

## Summary

Marks the current buffer tab, the current tab-page number, the focused window's winbar name, and the shown view of a slot header in bold with no accent fill, and removes the file icon from each tab. The tab row had four surfaces competing for the one accent, against the design rule of one accent per surface.

---

## Changes

- Change `TabLineSel` to the palette's text on its background in bold at every color depth, so the selected tab is the editor's own background with no fill.
- Add the highlight group `TabLineName` (bold, the tab row's own background, a new `TAB_NAME` color role) for the winbar name of the current window, the current page number, and the shown view name; the syntax groups move up by one id.
- Remove the file icon and the space after it from each tab, so a tab is the name, the modified mark, and padding.
- Draw the tab row without a fill under 16 colors and NO_COLOR, keeping the selected tab and current page number bold and every other name in the normal foreground, through the new `TabBar#bare=` set from the frame presenter.
- Replace the tab, winbar, and theme requirements in the buffer-tabs, breadcrumbs, and color-themes specs, and archive the change.
- Document in `docs/compatibility.md` that `gt` moves between buffer tabs and the tab pages are the numbers at the right.
- Update the tab row tests and snapshots at 24-bit, 256, 16 colors, and NO_COLOR, which fail against the old fill, and the definition, slot, flow, and breadcrumb tests for the icon-free row.

---

## Testing

- Run the fast stages of `make check` at the final implementation commit (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates), all pass
- Run `make spec-validate` after the archive, 56 of 56 items pass
- Security review of the committed diff, no High, Medium, or Low findings
- Benchmark review, passes with no blocking finding
- Quality review of the diff, four findings added, two fixed and two recorded in the findings file

---

## Notes

The requirement "The editor's own highlights are groups too" of `color-themes` lists a stale group count and is left alone; the new group is recorded in the findings file. NO_COLOR keeps the terminal colors elsewhere and takes the 16-color tab row only through `TabBar#bare=`.
