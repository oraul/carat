feat(render): draw the sign column one cell wide

## Summary

Draws the sign column of a buffer with signs one cell wide, the glyph in its kind's group or a blank in SignColumn, so the line numbers and the text sit one cell nearer the window's edge. The two-cell column spent a cell of text width on padding, and the Facet plan the user accepted draws the sign column one cell wide, always.

---

## Changes

- Change `Window::SIGN_WIDTH` to 1, so the gutter counts one cell for signs and the cursor, the view, and the width a split needs follow it
- Change the frame presenter to fill one SignColumn cell per row and cut a sign's glyph to its first character
- Change the screen-rendering spec so the sign column is one cell wide
- Update the frame presenter and language server tests and the frame snapshot to show the sign in one cell and the text column one cell nearer
- Document the one-cell sign column in the README, the architecture's FramePresenter entry, and the compatibility table
- Record the change's three non-blocking review findings in its findings file and apply the feature lane's plan to its queue

---

## Testing

- Run the security review of the committed diff at 657ef663efff, pass with no High, Medium, or Low finding
- Run the checker's stages at 657ef663efff (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the quality review at 657ef663efff, including the re-review of the repaint test fix and the findings commit, pass with no blocking finding and the advisories recorded
- Run the benchmark review at 657ef663efff, pass with the lh scenario held at 26.0 allocations per key
- Run make spec-validate after the archive, all 54 items pass

---

## Notes

The sign column stays one cell for every sign; an option.signcolumn setting and choosing the most severe of two owners' signs on one row are left for later Facet items. A plugin glyph longer than one character now shows only its first character, since every icon set glyph is one cell wide.
