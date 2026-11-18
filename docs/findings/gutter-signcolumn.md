
### The check starts gates before test-build has written the test runner
- Location: tools/run_state.sh, STAGE_AFTER (the stage order of check-run)
- Why: the snapshots gate of tools/gates.sh runs build/test/run_all whenever a commit changes a test/*.expected, but STAGE_AFTER has no gates:test-build pair, so when the carried stages leave the queue short, gates starts as soon as docs-lint ends (about 27 s) while test-build still compiles (about 150 s), fails with "build/test/run_all is missing", and the check kills test-build; it failed this way at 118500e1d053 although make test-build then make gates pass in the lane.
- Fix: add gates:test-build to STAGE_AFTER, with a tools-test case that a check whose head changes a snapshot starts gates only after test-build passed.

### The cell after the sign is checked only as not SignColumn

- Location: test/adapters_frame_presenter.rb:512
- Why: the check compares f.cell(0, 1).hl == D::Highlight::SIGN_COLUMN against false, which passes for any other group, so a wrong group in the number column goes unnoticed.
- Fix: assert the number column's own group, the presenter's line number highlight, at f.cell(0, 1).hl.

### The compatibility row misstates Neovim's sign column width

- Location: docs/compatibility.md:541
- Why: it says Neovim draws signcolumn=yes:1 one cell where its default auto takes two, but Neovim reserves two cells per sign column for both yes:1 and auto (auto:1), as the proposal itself says.
- Fix: write that the column is one cell where Neovim's sign column (yes:1 or the default auto) takes two.

### The group-only repaint check draws into a freshly allocated frame

- Location: test/adapters_frame_presenter.rb:270
- Why: the resize to 7 rows at :259 allocates both frames anew, so the repaint check draws into a fresh second frame that repaints every row whatever the record holds, and does not prove task 1.3's claim that a group-only change repaints.
- Fix: draw once more at 7 rows before placing the warning-group sign, so the checked frame already holds the same glyph in the error group.
### Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)
- Location: `tools/run_state.sh` groom (the fold that deletes the findings files), docs-lint stage
- Why: groom deleted the findings directory while a carried backlog entry still named it in backticks, so sprint-18-records failed its first check at 399adffe0be5 (docs-lint) and needed a contributor fix and a hand edit of groom output; check first passes 168/172 overall.
- Fix: groom output passes `make docs-lint` as written; accepted by a tools-test case folding a findings file whose entry names the removed directory, and the next 3 records runs passing check first.

### Records changes spend fix rounds on advisories only groom may fix (sprint-18-records retro 12)
- Location: `.claude/workflows/deliver-change.js` review rounds on a records change
- Why: 4 of 7 first-round advisories (backlog duplicates, stale security entries, fold format, map repeat) need backlog entries merged or removed, which CLAUDE.md leaves to groom, and 3 of the 4 second-round advisories repeat them with shifted lines; rework 2 with 0 blocking, reviews=25498/34 (29.5% of 86,421 output, 26% of 129 calls).
- Fix: an advisory in groom's own output on a records change goes to the findings file with no fix round; accepted when the next 3 records runs show rework 0 when blocking is 0. Near `review-lite`.

### The benchmark agent runs on records changes that touch no code (sprint-18-records retro 13)
- Location: `.claude/workflows/deliver-change.js` bench phase
- Why: on sprint-18-records it rebuilt dev-build, test-build, and bench-budget in the lane and a base worktree to find allocations and rounds equal: bench=4721/14 (10.9% of 129 calls); sprint-16-records bench=3547/6, sprint-17-records bench=4147/6.
- Fix: a change with no file under `carat/`, `bench/`, or the Makefile records the bench phase as skipped with no agent; accepted when records runs show bench 0/0. Joins `bench-skip-no-code`.
