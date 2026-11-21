# Backlog: openspec/specs/command-palette/spec.md

## The palette-pad-crash scenarios drift from their tests

- Where: `openspec/specs/command-palette/spec.md` lines 87 to 92 bind `window.split` while `test/editor_palette.rb` line 141 binds `insert.newline`; `openspec/specs/key-hints/spec.md` line 102 remaps `<leader>xa` while `test/editor_key_hints.rb` line 128 sets a group name for `<leader>xy`, since a project file reads no remap, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `menu-hints`.
- Why it matters: a scenario is meant to describe the setup its test runs; a reader who reproduces the scenario takes a path the test never covers.
- Fix outline: word the palette scenarios after `insert.newline` and the hint scenario after a group name of fifty wide characters whose widest row is 77 of 78 cells, through a proposal.
- Also: test/editor_palette.rb, openspec/specs/key-hints/spec.md, test/editor_key_hints.rb
- Category: pipeline
- Added: 2026-11-09

### openspec/specs/command-palette/spec.md:9 wide-key scenarios name another action than the test

Spec and test drift (cited at the change's delta spec, now synced into the main spec): the scenarios A key of wide characters and A key with combining marks bind window.split, but test/editor_palette.rb:250 binds insert.newline. Fix: make the scenarios name insert.newline (or the test bind window.split).
- Also: test/editor_palette.rb
- Category: pipeline
- Added: 2026-11-14
