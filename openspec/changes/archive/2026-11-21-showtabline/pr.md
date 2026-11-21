feat(options): add showtabline to show the tab row never, with two files, or always

## Summary

Adds `option.showtabline`, Neovim's 0, 1, or 2, so the top tab row never shows, shows only with two or more tab pages or files, or always shows, with 2 as the shipped default. Until now the row showed only from two tab pages or two files, while docs/design.md says the open file always has a tab and the compatibility table listed `showtabline` as missing.

---

## Changes

- Add `option.showtabline` to `Options` as an integer from 0 to 2, read from `option.*` configuration lines, where any other value is reported as `file:line: option.showtabline takes a number from 0 to 2` and the earlier value is kept.
- Change `BufferList#tab_row?` to take the option beside the tab page count, and pass it from `ArrangeView` and `FramePresenter` so the rows reserved and the row painted agree.
- Add `option.showtabline 2` to config/default.caratrc and its generated mirror, while an `Options` built in code keeps 1, the earlier rule.
- Add `showtabline` and `stal` to the `:set` words that answer Not implemented, since `:set` handles no numeric option yet.
- Change the test configuration `FixedConfig.defaults` to append `option.showtabline 1` so existing frame snapshots stay as they are, and add `FixedConfig.shipped` for the shipped defaults alone.
- Add table-driven rows for each value with one and with two files in the options, arrange view, frame presenter, and editor tab tests, plus `:set showtabline` and `:set stal` rows in the syntax test.
- Change the smoke test's window-move cursor row and PageDown page lines for the tab row the shipped default now shows on one file.
- Document the option in the buffer-tabs and config-files specs, docs/compatibility.md, the README option list, docs/architecture.md, docs/design.md, and the code map.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding.
- Run the checker's stages at 6dac495b907d (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, gates, tools-test, metrics), every stage passes, test-run 120/120 and spinel-doctor clean.
- Run the benchmark comparison against main's recorded figures, pass with `lh` holding 25.0 allocations.
- Run `make spec-validate` after the archive, 55 passed and 0 failed.

---

## Notes

`:set showtabline=N` comes with set-options, so for now the option is read from configuration lines only. The accent fill of the active tab and the 16-color TabLine contrast are left to `one-accent`, as docs/design.md Known drift says.
