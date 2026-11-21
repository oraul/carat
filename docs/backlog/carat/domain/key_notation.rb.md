# Backlog: carat/domain/key_notation.rb

## Key codes matched with case/when beside same-named String and Symbol constants

- Where: `carat/domain/key_notation.rb:143` and `:150`, `carat/adapters/key_decoder.rb:60` and `:61` (`Key::DELETE`, `Key::INSERT`).
- Why it matters: the shape `docs/spinel-notes.md` (Known miscompilations) says the pinned Spinel may fold to false; only the table tests in `test/domain_keys.rb` and `test/adapters_key_decoder.rb` keep it working. Periodic quality, blocking shape.
- Fix outline: rewrite both lookups as `==` guard returns, as `Mode.visual_kind` does. Queue item `periodic-blockers-b`.
- Also: carat/adapters/key_decoder.rb, docs/spinel-notes.md, test/domain_keys.rb, test/adapters_key_decoder.rb
- Category: editor
- Added: 2026-11-10

## KeyNotation branches on a Symbol constant the notes call miscompiled

- Where: `carat/domain/key_notation.rb:150`; `test/domain_keys.rb`. Periodic quality.
- Why it matters: `when Key::INSERT` has the shape `docs/spinel-notes.md` says folds to false, and no row formats `<Insert>` or `<Unknown>`.
- Fix outline: format rows for both; if they fail, guard returns as `Mode.visual_kind`. Queue item `spinel-workarounds`.
- Also: test/domain_keys.rb, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-10
