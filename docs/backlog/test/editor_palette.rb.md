# Backlog: test/editor_palette.rb

## cells_of in the palette test returns an array no caller reads whole

- Where: `cells_of` in `test/editor_palette.rb` line 66, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `menu-hints`.
- Why it matters: it computes the row's total cells that no caller reads (only the second value is used) and returns several values in an array, against the test-helper rule of `CLAUDE.md`.
- Fix outline: return only the description's start cell as an Integer and drop the total.
- Also: CLAUDE.md
- Category: code-quality
- Added: 2026-11-09

### test/editor_palette.rb:131 wide_session duplicates plugin_session

Duplication: wide_session repeats plugin_session line for line except the plugin it passes. Fix: give plugin_session the plugin as a parameter and call it with Wide.new and Carat::Plugins::Hello::Plugin.new.
- Category: code-quality
- Added: 2026-11-14
