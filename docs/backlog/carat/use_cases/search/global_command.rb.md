# Backlog: carat/use_cases/search/global_command.rb

## No test runs a global after one stopped by a failing command

- Where: the `ensure` of `GlobalCommand#call` in `carat/use_cases/search/global_command.rb` (line 176 at 76fa78b), which resets `@busy` and clears the marks on the early return. Quality advisory of `buffer-global`.
- Why it matters: if Spinel skipped the `ensure` on that return, every later global would answer `E147` as if it ran inside a global, and no test would notice.
- Fix outline: add a row to `test/editor_global.rb` such as `:g/a/foo` followed by `:2g/a/d`, expecting the delete and not `E147`. Queued in `global-tidy`.
- Also: test/editor_global.rb
- Category: editor
- Added: 2026-11-05

## GlobalCommand#remember repeats SubstituteLines#remember

- Where: `carat/use_cases/search/global_command.rb` line 81 and `carat/use_cases/search/substitute_lines.rb` line 113, at 7711421. Periodic quality. Queue item `substitute-tidy`.
- Why it matters: the same four writes of a used pattern, so a fix to one misses the other.
- Fix outline: one domain function both call.
- Also: carat/use_cases/search/substitute_lines.rb
- Category: editor
- Added: 2026-11-09

### GlobalCommand#remember repeats SubstituteLines
- Location: carat/use_cases/search/global_command.rb:81; carat/use_cases/search/substitute_lines.rb:113
- Why: the pattern into LastSubstitute and LastSearch, the / register, and the history written twice. Folded into editing-dedup-a.
- Fix: one shared helper both call.
- Also: carat/use_cases/search/substitute_lines.rb
- Category: editor
- Added: 2026-11-17

### GlobalCommand and SubstituteLines repeat remember

- Location: carat/use_cases/search/global_command.rb:81, substitute_lines.rb:113 (sweep, quality).
- Why: both make the same four writes: last substitute pattern, last search, the / register, the history.
- Fix outline: one shared helper both call.
- Category: editor
- Added: 2026-11-17

### Global :p copies every earlier printed line per match
- Location: carat/use_cases/search/global_command.rb:174
- Why: each :p in a global copies every earlier printed line into a new string, quadratic in the lines printed (:g/./p on a large file).
- Fix: append the printed lines to one mutable string or array and build the Outcome.from_print once after the loop.
- Category: editor
- Added: 2026-11-18
