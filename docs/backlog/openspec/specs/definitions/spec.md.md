# Backlog: openspec/specs/definitions/spec.md

## No test covers :wa over a modified read-only buffer and a writable one

- Where: the definitions spec requirement on read-only targets (`openspec/specs/definitions/spec.md`) says `:wa` and `:wqa` still write the other modified buffers, and `test/adapters_definitions.rb` has no row for it. Quality advisory in `gd-ghost-tab`.
- Why it matters: a `:wa` that stops at the first E45 would leave the user's writable edits unsaved without a failing test.
- Fix outline: add a scenario and a row that modifies `a.rb` and the read-only target, runs `:wa`, and asserts `a.rb` is written while E45 is reported for the read-only one.
- Also: test/adapters_definitions.rb
- Category: pipeline
- Added: 2026-11-10
