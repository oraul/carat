# Backlog: carat/domain/vim_pattern.rb

## A # search history entry is cut at its ?

- Where: `VimPattern.escape` in `carat/domain/vim_pattern.rb` line 111, fed by `FindMatch#word` at `carat/use_cases/search/find_match.rb` line 119, at 38628bb (periodic quality). Queued in `search-tidy`.
- Why it matters: the non-keyword text of `#` or `g#` enters the history with `?` unescaped and, recalled at a `?` prompt, is cut there.
- Fix outline: escape the delimiter of the direction, with an `editor_search` row.
- Also: carat/use_cases/search/find_match.rb
- Category: editor
- Added: 2026-11-09

## VimPattern and Search repeat a list and a test

- Where: `carat/domain/vim_pattern.rb` line 22 (the escapes listed twice) and `Search.action?` in `carat/domain/search.rb` line 42 (a prefix test every listed name passes), at 38628bb (periodic quality). Queued in `search-tidy`.
- Why it matters: each restates what the next line already says.
- Fix outline: drop the repeated list and one of the two tests.
- Also: carat/domain/search.rb
- Category: editor
- Added: 2026-11-09
