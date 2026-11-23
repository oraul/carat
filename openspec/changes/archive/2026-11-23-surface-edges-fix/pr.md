fix(tabs): drop tab separators, start tabs at the editor, head the sidebar

## Summary

Removes the separator glyph after each tab, starts the tab row at the editor's first column, heads the left sidebar with the project and branch, and draws blank rows instead of tildes below a sidebar's text. The design draws no tab separator, and the tab row, the explorer's head row, and the sidebar tildes did not match it.

---

## Changes

- Remove the tab separator and its cell from the tab frame, so tabs sit without a glyph between them in every color mode.
- Start the tab row at the sidebar's column plus its width plus one, and at column zero with no sidebar.
- Paint the project name and branch over the left sidebar on the tab row, with the project bright, the dot faint, and the branch dim.
- Add Slot#headed? so a left sidebar holding one view has no separate head row, and a slot holding two views keeps it.
- Draw blank rows below a sidebar's text instead of tildes.
- Update the buffer-tabs, layout-slots, and screen-rendering specs, README.md, docs/compatibility.md, and docs/codebase-map.md.
- Add and update tests and snapshots for the tab row, the head, the slot header, and the sidebar rows at truecolor, 16 colors, and NO_COLOR.

---

## Testing

- Run the fast and full check stages at the final code commit (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the security review of the committed diff, no findings
- Run the benchmark review, pass with no blocking findings
- Run the quality review of the diff, five findings added and five recorded in the findings file

---

## Notes

Gaps outside this change, such as the project name lagging a working-directory change and the right sidebar keeping its title row, are recorded in docs/findings/surface-edges-fix.md. The dashed line at the sidebar edge comes from the terminal's padding and needs no change here.
