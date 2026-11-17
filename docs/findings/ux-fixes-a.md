
### A change touching no carat/, bench/, or test/ file still runs the benchmark phase
- Location: .claude/workflows/deliver-change.js, the benchmark phase (sprint-10-records retro note 4)
- Why: the records-only sprint-10-records spent 4,848 output tokens and 6 calls on the benchmark (9.3% of 52,240 output tokens, 7% of 86 calls) plus a base and a change build, while its check scoped the metrics stage out; bench first pass 117 of 118 over the history, allocations and rounds unchanged on every key.
- Fix: skip the benchmark phase, recording the skip, when the committed diff touches no file under carat/, bench/, test/, or the Makefile; accepted when the next records change shows a recorded skip and no skipped change later shows an allocation or rounds difference.

### The ProcessPort row still names capture(argv)
- Location: docs/architecture.md:213
- Why: the port takes capture(argv, environment) since #160, so the binding architecture table misstates the port.
- Fix: name the environment argument in the row.

### The ProcessPort row still names capture(argv)

- Location: docs/architecture.md:213
- Why: the port takes capture(argv, environment) since #160, so the binding architecture table misstates the port.
- Fix: name the environment argument in the row.

### The lsp accents at 16 colors read poorly on the light gray bar

- Location: carat/domain/themes.rb:212
- Why: at 16 colors the lsp accents PANEL_YELLOW 3 and PANEL_GREEN 2 now sit on PANEL's 7 in carat-dark, carat-light, one_dark, and one_light; dark yellow and green on light gray read near 1.5:1 in common terminal palettes, where the dark palettes had 11 and 10 on the terminal's background, and no test measures 16-color contrast.
- Fix: give these palettes 16-color accents that read on 7 (0 with bold, or 4 and 1), or keep a 16-color background that suits 3 and 2, and assert the pairs in test/domain_theme.rb.

### The status bar's diagnostics counts draw on the terminal's background

- Location: carat/adapters/status_bar.rb:243
- Why: the diagnostics counts on the bar still draw in DIAGNOSTIC_ERROR, WARN, INFO, and HINT, whose background is NONE (carat/domain/themes.rb:125), the same hole in the bar ux-fixes-a closed for the lsp slot.
- Fix: add PANEL-backed status diagnostic groups, as for the lsp slot, and extend lsp_holes in test/domain_theme.rb to them.

### The palette's pad appends one space per loop pass

- Location: carat/use_cases/discovery/follow_palette.rb:296
- Why: pad appends one space per loop pass, redoing the padding DisplayWidth.fit already does, with a string per pass on a path drawn after each key while the palette is open.
- Fix: cell << " " * (width - used) if used < width, as DisplayWidth.fit does.
### A change touching no carat/, bench/, or test/ file still runs the benchmark phase
- Location: .claude/workflows/deliver-change.js, the benchmark phase (sprint-10-records retro note 4)
- Why: the records-only sprint-10-records spent 4,848 output tokens and 6 calls on the benchmark (9.3% of 52,240 output tokens, 7% of 86 calls) plus a base and a change build, while its check scoped the metrics stage out; bench first pass 117 of 118 over the history, allocations and rounds unchanged on every key.
- Fix: skip the benchmark phase, recording the skip, when the committed diff touches no file under carat/, bench/, test/, or the Makefile; accepted when the next records change shows a recorded skip and no skipped change later shows an allocation or rounds difference.

### The follow_palette map entry names DisplayWidth.fit

- Location: docs/codebase-map.md:169
- Why: the follow_palette entry says its columns are fit by DisplayWidth.fit, which the file no longer calls since ux-fixes-a, so the map misdescribes the file.
- Fix: name the private pad and kept_bytes on DisplayWidth.bytes_within instead.
