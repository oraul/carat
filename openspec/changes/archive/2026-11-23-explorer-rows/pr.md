feat(explorer): start the tree at the root's entries and mark the current row

## Summary

The explorer tree now starts at the root's entries instead of a row naming the project, and the current file's row is drawn as a full-width highlight with a leading bar. The tab row already heads the column with the project, so the root row repeated it, and the one-cell chevron mark differed from the current row that the design document describes.

---

## Changes

- Remove the root line from the tree: the entries of the root sit at depth 0, the keys that acted on the root line are gone, and `a` on a top-level entry or in an empty tree creates in the root.
- Add the host request `mark_scratch_row` (plugin API 2.17) and `Buffer#marked_row`, so a plugin marks one row of its scratch buffer and `set_scratch_lines` clears the mark.
- Draw a marked row in the frame presenter as the selection fill across the window with the bar cell in the mark group, and the bar alone under NO_COLOR.
- Mark the current file's row from the explorer after every fill and refresh.
- Change the `current` icon to the bar in the unicode set and `|` in the ascii set.
- Update the file-explorer, icons, and plugin-host specs, `docs/plugins.md`, `docs/design.md` (the closed drift row), `docs/codebase-map.md`, and the README file tree paragraph.
- Add tests for the first tree row, the current row, the marked row with its clearing and NO_COLOR paths, the keys on an empty tree, the icon glyphs, and the API version.

---

## Testing

- Run the security review of the committed diff, no High, Medium, or Low findings
- Run the benchmark review, pass with no blocking finding
- Run the check stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) at the implemented commit, all pass
- Run `make spec-validate` after the archive, 56 items pass

---

## Notes

The nerd icon set keeps a private use glyph for `current` because the icon table's test requires that of every nerd glyph. The current row's icon takes the selection color rather than its file-type color, and its label is not bold. Both are recorded in `docs/findings/explorer-rows.md`.
