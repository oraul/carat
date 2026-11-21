# Backlog: carat/use_cases/search/preview_search.rb

## Incremental search spends the full search budget on every key

- Where: `PreviewSearch#call` in `carat/use_cases/search/preview_search.rb` (line 48), which resets the budget to `Domain::SearchBudget::SEARCH`. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: with `incsearch` on, a costly pattern spends about 1.5 seconds on each key typed at the prompt, so typing stalls key by key.
- Fix outline: give the preview its own smaller `SearchBudget` constant and end the preview without a match when it stops, with a `use_cases_search` row. Queued in `search-tidy`.
- Category: editor
- Added: 2026-11-04

## Search and prompt findings of the periodic review at 186ddfb

- Where: `carat/use_cases/search/preview_search.rb` line 57 sets the cursor column unclamped (a `$` match stands past the last character); `carat/domain/search_prompt.rb` line 186 `restore` clamps to the line length, not length - 1; `carat/domain/vim_pattern.rb` line 23 lists the escapes t, e, and r twice; `carat/use_cases/search/find_match.rb` line 134 `blank?` repeats `Motions.code_class(code, false) == 0`. Periodic quality at 186ddfb, queued in `search-tidy`.
- Why it matters: two normal-mode cursors off the line, a doubled comment, a repeated class check.
- Fix outline: clamp through `state.clamp_col`, clamp `restore` to length - 1 (0 on an empty line), each with an `editor_search` row; drop the second list; define `blank?` through `code_class`.
- Also: carat/domain/search_prompt.rb, carat/domain/vim_pattern.rb, carat/use_cases/search/find_match.rb
- Category: editor
- Added: 2026-11-10
