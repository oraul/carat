feat(finder): draw the selected row as a bar, the selection fill, and a bold label

## Summary

Draws the finder's highlighted row as design section 5 decides: a sapphire bar, the selection fill, and a bold label, with no leading greater-than mark, in the files, grep, buffers, and recent pickers. That mark was one of the four selection marks design section 7 lists as drift, and the row had no fill or weight. Two new float span groups carry the bar and the label, so a plugin can style them through plugin API 2.15.

---

## Changes

- Change the finder pickers to mark the highlighted row with a ▎ bar instead of a greater-than sign and to style the list float after every refill, the row on the selection fill with its bar and label bold, reverse and bold at 16 colors.
- Add the UI groups PmenuMarkSel and PmenuLabelSel in every palette, before StatusLineDim, the bar in a new MARK color role held to 3:1, and raise the plugin API to 2.15 so a float span may carry them and syntax_group resolves them.
- Change float painting under NO_COLOR to draw spans in the two new groups only, so the palette and the command-line menu stay unpainted as before.
- Change the grep preview's matched line to start with the same ▎ bar.
- Change the grep picker to build each float's box key once per refresh and a plain row with its mark in one string, holding its allocations per key under main's.
- Add tests and snapshots for the selected row under truecolor, 16 colors, NO_COLOR, and option.icons ascii, and for the new span groups.
- Remove the finder's row from the Known drift table of docs/design.md and document the look in docs/plugins.md, docs/compatibility.md, docs/architecture.md, docs/codebase-map.md, and the README.
- Archive the OpenSpec change and sync the file-finder, plugin-host, and color-themes specs.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding.
- Run the check stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass.
- Run the benchmark review against main's recorded figures, pass with no blocking finding.
- Run the quality review of the diff, four findings, three fixed and one recorded in the change's findings file.
- Run make spec-validate after the archive, all 56 items pass.

---

## Notes

The backlog advisory about a finder FRAME literal ignoring winborder no longer holds: the plugin has no such constant and sizes its boxes from the host's float frame. The matched letters in sapphire, the query row inside the float, the other three selection marks, and a fill on the grep preview's matched line are left for later changes.
