# Backlog: test/editor_key_hints.rb

## The discovery tests copy their session helper

- Where: `plugin_session` in `test/editor_key_hints.rb` line 27 and in `test/editor_palette.rb` line 21, each repeating its file's `session` but for the plugin list, and the magic slice `row_of(...)[0, 55]` in `test/editor_palette.rb` line 96, at d828abb. Quality advisories in `discoverability`.
- Why it matters: two copies of the same setup drift, and a slice at a counted width breaks silently when a description changes.
- Fix outline: give each `session` a `plugins` argument (`plugins: []` at the existing rows) and drop `plugin_session`; assert `start_with?` on the expected prefix, or compare the whole rstripped row.
- Also: test/editor_palette.rb
- Category: code-quality
- Added: 2026-11-09

### Quality advisory: sized_session repeats session (test/editor_key_hints.rb:65)

- Location: test/editor_key_hints.rb:65
- Why: duplication; sized_session repeats session (line 11) but for the cols and the wait count.
- Fix: give session a cols parameter (the existing callers passing 80) and drop sized_session.
- Category: code-quality
- Added: 2026-11-14
