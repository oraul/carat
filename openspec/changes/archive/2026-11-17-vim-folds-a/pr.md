feat(folds): add manual folds with zf, zo, zc, za, zd, and zE

## Summary

Adds manual folds per window, as Neovim's foldmethod=manual: zf with a motion or a selection creates a closed fold, zo, zc, za, zd, and zE open, close, toggle, and delete folds, a closed fold is drawn as one row, j and k pass it as one line, and a linewise operator on it acts on all its lines. Carat had no folds at all, so a long buffer could not be collapsed to the part being read; this is part a of the vim-folds user request, part b taking zR, zM, zj, zk, [z, ]z, and the fold ex commands.

---

## Changes

- Add the Folds domain record holding a window's folds, their nesting, their shifting with the buffer's edits, and Neovim's default fold text, with Window gaining a folds member copied by a split
- Add zf in normal and the visual modes through Operate and the new ChangeFolds use case and FoldHandler, and zo, zc, za, zd, and zE in normal mode, with E490 when no fold is under the cursor
- Change the frame presenter to draw a closed fold as one row with its line number and place the cursor and floats by screen row, the view scrolling and syntax highlighting counting the fold as one row
- Change j and k to pass a closed fold as one line, landing on its first line, and keep a cursor out of a closed fold's inner lines, o and O opening their line outside the fold
- Change a linewise operator starting on a closed fold to act on all its lines, so dd, 2dd, dj, and yy cover the fold as Neovim does
- Bind the fold keys in config/default.caratrc, mirrored in the generated default config, with their rows in docs/actions.md
- Add test/editor_folds.rb, a table-driven test over the editor and its screen, and test/domain_folds.rb, with their snapshots
- Document the fold rows in docs/compatibility.md, the new files in docs/codebase-map.md, the window record in docs/architecture.md, and manual folds in the README feature list
- Add the folds capability spec and the archived OpenSpec change, and record the findings, the plan, and the metrics history

---

## Testing

- Run the security review of the committed diff at 1c231e6b7efc, pass with no High, Medium, or Low finding
- Run the quality review at 1c231e6b7efc, pass with no blocking finding, and the benchmark review, pass with allocations and rounds within main's figures (lh 26, j 27 allocations)
- Run the checker's stages at 1c231e6b7efc (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run make spec-validate after the archive, 54 of 54 items pass

---

## Notes

Folds are kept per window and dropped when the window shows another buffer; a closed split's folds stay tracked by its buffer until a follow-up untracks them, recorded in docs/findings/vim-folds-a.md with the visual-mode fold adjustment and the put-below-fold parity gap. Out of scope beyond part b: zF, zD, zO, zC, zA, zv, zx, counts before zo and zc, other foldmethods and fold options, the Folded highlight group, and search, G, and jumps opening a fold.
