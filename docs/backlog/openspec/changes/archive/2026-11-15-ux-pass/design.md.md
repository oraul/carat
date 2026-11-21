# Backlog: openspec/changes/archive/2026-11-15-ux-pass/design.md

### The ux-pass start timings have no saved evidence

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:52`.
- Why: the two start rows of the timing table (6.5 to 10 ms, 632 ms; 7 to 10 ms, 8 ms, 260 to 520 ms with the server) cite no recorded run: first-start, first-file, and empty-new-file record first byte none and settled none, and `timings.txt` has only `start greet.rb settled 10.8 ms`; quality advisory from ux-pass.
- Fix: add the start runs to `timings.txt` or drop the figures that were not recorded.
- Category: pipeline
- Added: 2026-11-15

### The ux-pass screen headers name only the last keys written

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:19`, `openspec/changes/archive/2026-11-15-ux-pass/tasks.md:5`.
- Why: a screen header names only the last keys sent (`empty-explorer-help` says `keys: ?`, not `<Space>e` then `?`) and the start screens leave the keys empty with times none, so the claim that each header names its keys does not hold alone; quality advisory from ux-pass.
- Fix: write the full key sequence from the named start in each header, or say in the design that the screen list carries it.
- Also: openspec/changes/archive/2026-11-15-ux-pass/tasks.md
- Category: pipeline
- Added: 2026-11-15

### The ux-pass finding 6 reproduction names the wrong file

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:66`.
- Why: finding 6's reproduction starts on `notes.txt`, but its evidence `time-insert-char` is `greet.rb` with the canned server (row 23 shows `greet.rb` and `fake-lsp`), so following it does not reproduce the screen; quality advisory from ux-pass.
- Fix: name `greet.rb` and the keys the screen records in the reproduction and in the backlog entry of finding 6.
- Category: pipeline
- Added: 2026-11-15
