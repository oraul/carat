# Backlog: test/domain_fuzzy_match.rb

## The completion ranking table checks a copy of the ranking

- Where: `ranked` in `test/domain_fuzzy_match.rb` (line 17 at 334d899) copies the insertion sort of `ShowCompletion#ranked` in `carat/use_cases/completion/show_completion.rb`. Quality advisory in `completion`.
- Why it matters: the ranking table checks the test's copy, not the production order, so a change to `ShowCompletion`'s ranking passes the test unseen.
- Fix outline: move the ranking into the domain (`FuzzyMatch.rank` or `CompletionMenu#rank`), call it from `ShowCompletion`, and point the table at it.
- Also: carat/use_cases/completion/show_completion.rb
- Category: code-quality
- Added: 2026-11-07
