# Backlog: carat/domain/last_search.rb

## Public helpers no other file calls

- Where: `carat/domain/last_search.rb` line 111 (touch), `carat/use_cases/actions/action_table.rb` line 96 (handler_at), `carat/domain/buffer.rb` line 185 (detect_filetype, named on the map's buffer line), at c1b3a12 (periodic quality). Queued in item 46. At 38628bb also `ExTable#count` and the public `handler_at` (`carat/use_cases/ex/ex_table.rb` lines 99 and 104, periodic quality).
- Why it matters: dead public surface invites callers that bypass the owner.
- Fix outline: move the three under private and drop detect_filetype from the map line.
- Also: carat/use_cases/actions/action_table.rb, carat/domain/buffer.rb, carat/use_cases/ex/ex_table.rb
- Category: editor
- Added: 2026-11-09

## LastSearch keeps the pattern twice

- Where: `carat/domain/last_search.rb` line 16, at b76b722. Periodic quality. Queue item `search-tidy`.
- Why it matters: `pattern` always equals `compiled.source`, one fact kept twice.
- Fix outline: drop the member and read `compiled.source` in `any?` and `recompile`.
- Category: editor
- Added: 2026-11-09
