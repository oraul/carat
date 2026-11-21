# Backlog: carat/use_cases/ex/delete_command_handler.rb

## :d and :s each compute a count's range

- Where: `DeleteCommandHandler#call` in `carat/use_cases/ex/delete_command_handler.rb` (line 42 at 76fa78b) and `SubstituteLines#call` in `carat/use_cases/search/substitute_lines.rb` (lines 66 to 70). Quality advisory of `buffer-global`.
- Why it matters: both turn a count into a range the same way (the first line becomes the last, the last moves count minus one lines down, clamped to the buffer's last line), so a fix to one, such as Vim's handling of a count past the end, can miss the other.
- Fix outline: one domain helper, for example on `ExRange`'s result, that takes the range, the count, and the line count and returns the new first and last, called by both. Queued in `global-tidy`.
- Also: carat/use_cases/search/substitute_lines.rb
- Category: editor
- Added: 2026-11-05
