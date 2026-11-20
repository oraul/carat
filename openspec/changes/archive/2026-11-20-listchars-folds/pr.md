feat(options): add the list and listchars whitespace marks

## Summary

Adds Neovim's list and listchars options, which draw marks over the tabs, trailing spaces, and no-break spaces of file windows in the indent guides' quiet color, off by default, with Neovim's ascii marks under option.icons ascii. No option showed where a tab, a trailing blank, or a no-break space sits, and a tab painted as blank cells.

---

## Changes

- Add option.list (off in fresh options and as shipped) and option.listchars with Neovim's keys tab, trail, and nbsp, Neovim's default value in fresh options and the shipped tab:→ ,trail:·,nbsp:␣ in config/default.caratrc, mirrored by make gen-config, an unknown key or malformed value reported as a file:line problem with the earlier value kept.
- Add WhitespaceMarks in carat/adapters/whitespace_marks.rb, which paints the marks over the text cells of file windows' rows after the syntax tokens and indent guides and before the search matches and the selection, drawing Neovim's ascii marks for a mark outside ASCII under option.icons ascii, and none in plugin windows, floats, or closed fold rows.
- Change FramePresenter to paint the marks in file text rows and to repaint when the marks' settings change, through their stamp in the frame's geometry key.
- Change the Whitespace highlight to take the indent guides' color role in every palette (carat-dark 30364b, carat-light d8dce8, basic color 8 at 16 colors), the mark characters still showing under NO_COLOR.
- Change :set list, :set listchars, and :set lcs to answer Not implemented, as the other options read only from configuration lines.
- Add test/adapters_whitespace_marks.rb with frame rows for each mark on and off, the ascii form, a match and a selection over a mark, and a float, and extend the options, theme, and syntax tests and their snapshots.
- Document the marks in docs/compatibility.md, README.md, docs/architecture.md, and the code map, and add the whitespace-marks spec and the Whitespace requirement change of the color-themes spec.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding, and the benchmark review, pass.
- Run the checker stages docs-lint, dev-build, test-build, test-run (119 of 119 tests pass), diagnose, bench-budget, tools-test (1944 of 1944 pass), gates, and metrics at the reviewed commit, all exit 0.
- Run make spec-validate after archiving, 55 of 55 items pass.
- Run make gates and make docs-lint on the final branch, both pass.

---

## Notes

The closed fold's look, its text and fill in Folded with one cell of padding, is the second half of the queue item and is split off as the queued feature folded-row. Neovim's other listchars keys, :set list itself, and a window-local list are left out. Fresh options keep Neovim's default listchars while the shipped configuration carries the Unicode marks, as the indent guides do.
