# Backlog: carat/domain/icons.rb

### The nerd set's current marker is still a chevron
- Location: `carat/domain/icons.rb` (the nerd `current` glyph, U+F054)
- Why: `docs/design.md` section 5 says no selected row takes a `>` or `›`, but `test/domain_icons.rb` requires every nerd glyph to be a private use code point, and `▎` is not one, so the nerd set keeps its chevron at the explorer's current row.
- Fix: a private use glyph that is a left bar (or a decision that the nerd set's `current` may be `▎`, with the test's rule relaxed for that name).
- Also: docs/design.md, test/domain_icons.rb
- Category: editor
- Added: 2026-11-24
