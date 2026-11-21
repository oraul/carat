# Backlog: test/editor_floats.rb

## :close in a float is not tested

- Where: `test/editor_floats.rb` line 116 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: the spec requires `:close` in a float to close only the float, but only `:q` and Ctrl-W c are tested, so a regression of `:close` would pass.
- Fix outline: add a `:close` case beside the `:q` and Ctrl-W c cases.
- Category: code-quality
- Added: 2026-11-07

## Test helpers are copied across files

- Where: `test/editor_floats.rb:30`; the `strings` helper in `test/domain_buffer.rb`, `test/domain_edits.rb`, `test/domain_global.rb`, `test/editor_floats.rb`. Periodic quality.
- Why it matters: two bodies for one helper.
- Fix outline: build the editor from `configured`, one `strings` helper in `Carat::Testing`. Backlog batches (test hygiene).
- Also: test/domain_buffer.rb, test/domain_edits.rb, test/domain_global.rb
- Category: code-quality
- Added: 2026-11-10
