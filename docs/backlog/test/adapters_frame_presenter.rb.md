# Backlog: test/adapters_frame_presenter.rb

### Two tests scan the palette rows by hand (sprint-18 review quality)
- Location: `test/adapters_frame_presenter.rb:183` (`palette_rgb`), `test/domain_theme.rb` (`role_row`).
- Why it matters: the same lookup is written twice over the 4-value palette rows.
- Fix outline: one `Domain::Themes` reader of a role's 24-bit color, or one shared test helper, used by both.
- Also: test/domain_theme.rb
- Category: code-quality
- Added: 2026-11-18

### The group-only repaint check draws into a freshly allocated frame

- Location: test/adapters_frame_presenter.rb:270
- Why: the resize to 7 rows at :259 allocates both frames anew, so the repaint check draws into a fresh second frame that repaints every row whatever the record holds, and does not prove task 1.3's claim that a group-only change repaints.
- Fix: draw once more at 7 rows before placing the warning-group sign, so the checked frame already holds the same glyph in the error group.
- Category: code-quality
- Added: 2026-11-19

### The bracket pair table has no multibyte or scrolled row (sprint-19 review quality)

- Location: `test/adapters_frame_presenter.rb:167`
- Why: pair_case has no row with multibyte text before the bracket or a window scrolled sideways (left > 0), where code-point indexing and fill_columns clipping could go wrong.
- Fix: add a row with a non-ASCII character before ( and one scrolled left so only one bracket is visible. Queued in `render-tidy`.
- Category: code-quality
- Added: 2026-11-19
