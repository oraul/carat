# Backlog: carat/use_cases/ex/ex_table.rb

## ExTable keeps unread positions and an uncalled count

- Where: `carat/use_cases/ex/ex_table.rb` lines 16 and 56 (`@index` positions never read), 98 (`count`, no caller), 104 (`handler_at`, public only for `find`), at 7711421. Periodic quality. Queue item 41.
- Why it matters: dead API, and the comment reads the index as a lookup though it only refuses duplicates.
- Fix outline: delete `count`, make `handler_at` private, keep a set of taken names, and say so in the comment.
- Category: editor
- Added: 2026-11-09
