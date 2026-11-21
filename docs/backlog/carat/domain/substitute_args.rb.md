# Backlog: carat/domain/substitute_args.rb

## SubstituteArgs.parse tests for a leading blank it never receives

- Where: `SubstituteArgs.parse` in `carat/domain/substitute_args.rb:45`, the `first != 32 && first != 9` tests. Quality advisory at 127a14f.
- Why it matters: `ExGrammar` strips the arguments before they reach `parse`, so the tests never decide and read as if a blank delimiter were handled.
- Fix outline: drop the two tests, or say in the method's comment that `parse` accepts unstripped text and add a row that passes it. Queued in `substitute-structure`.
- Category: editor
- Added: 2026-11-04

## SubstituteArgs repeats the ex range number reader and the letter test

- Where: `carat/domain/substitute_args.rb` line 86 (`MAX_COUNT`), repeating `ExRange.line_number` (`carat/domain/ex_range.rb` line 73, `MAX_NUMBER`), and line 46, repeating `ExGrammar.letter?`. Periodic quality advisory at f31f4e8.
- Why it matters: two copies of one limit and one test in one domain drift apart when either changes.
- Fix outline: one capped number reader and one letter predicate in the domain, called from both. Queued in `substitute-structure`.
- Also: carat/domain/ex_range.rb
- Category: editor
- Added: 2026-11-04
