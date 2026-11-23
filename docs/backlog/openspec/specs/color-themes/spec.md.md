# Backlog: openspec/specs/color-themes/spec.md

### The color-themes requirement lists a stale count of groups
- Location: `openspec/specs/color-themes/spec.md`, the requirement "The editor's own highlights are groups too".
- Why: it names a count of highlight groups that no longer matches `Domain::Highlight` (TabLineName is id 69 and the syntax groups moved up by one), so a reader cannot check the list against the code.
- Fix: replace the number with a statement that every group of `Domain::Highlight` is drawn by each theme, and let `test/domain_theme.rb` hold the count.
- Also: test/domain_theme.rb
- Category: pipeline
- Added: 2026-11-23
