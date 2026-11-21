# Backlog: test/domain_selection.rb

### Test tables pass unconverted values

- Location: test/domain_selection.rb:47 and 49, test/editor_operators.rb:145-147, test/editor_insert.rb:40-42, test/editor_completion.rb:71 (sprint-4 sweep, quality).
- Why: table inputs reach the library unconverted, against the typed-helper rule.
- Fix: convert with .to_s, .to_i, or ints first.
- Also: test/editor_operators.rb, test/editor_insert.rb, test/editor_completion.rb
- Category: code-quality
- Added: 2026-11-14
