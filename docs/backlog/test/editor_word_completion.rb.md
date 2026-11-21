# Backlog: test/editor_word_completion.rb

## No test pins that typing with no popup costs nothing more

- Where: `test/editor_word_completion.rb` at 8f486e0 has no row for the spec scenario Typing costs nothing more (no buffer scan and no extra allocation per key with no popup). Quality advisory in `word-completion`.
- Why it matters: a change that scans the buffer on every insert-mode key would pass the suite unseen.
- Fix outline: assert that typing in insert mode with no popup leaves the menu unfilled, or add a bench scenario row that pins the allocations. Queued in `completion-tidy`.
- Category: ide
- Added: 2026-11-10
