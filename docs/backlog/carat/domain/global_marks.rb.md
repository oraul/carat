# Backlog: carat/domain/global_marks.rb

## GlobalMarks#active? is used only by its test

- Where: `GlobalMarks#active?` in `carat/domain/global_marks.rb` (line 25 at 76fa78b), called only by `test/domain_global.rb`. Quality advisory of `buffer-global`.
- Why it matters: dead code in the domain reads as behavior the editor relies on, and its test lines check nothing the editor does.
- Fix outline: use it in `shift` (`return unless active?`), which also skips the work on every splice outside a global, or drop it and its test lines. Queued in `global-tidy`.
- Also: test/domain_global.rb
- Category: editor
- Added: 2026-11-05
