# Backlog: carat/use_cases/syntax/highlight_view.rb

## G on a large file tokenizes every row above the end once

- Where: `Carat::UseCases::HighlightView#advance` in `carat/use_cases/syntax/highlight_view.rb`.
- Why it matters: the state of the last row depends on every row above it, so the first `G` on 100,000 lines of Ruby tokenizes all of them, about 68 ms in the benchmark (`make bench` scenario `G-ruby`); later jumps reuse the end states.
- Fix outline: if it matters on larger files, start from a sync point as Vim's `syntax sync minlines` does (tokenize a few hundred rows above the window from state 0 and accept a wrong state in rare cases), or tokenize the rest of the file in the background between keys once the main loop has an idle tick.
- Merged: ### G on a large file tokenizes every row above the end once
- Location: `carat/use_cases/syntax/highlight_view.rb` (`advance`), `test/editor_syntax.rb` "G tokenizes every row above the end once"; split off from syntax-tidy.
- Why: a jump to the end of a 100,000-line Ruby file tokenizes every row above it once, in one frame, to carry the exact state from the top; the specification "Only visible rows and the rows above them are tokenized" and the test that the last row keeps that state require it, so a faster jump is a behavior choice, not a bug fix.
- Fix: ask the user to choose between a sync point a bounded number of rows above the window (Neovim's syntax sync, colors approximate until the frontier reaches it) and spreading the tokenizing over idle frames (exact colors, the far rows plain at first); then change the syntax-highlighting requirement, `HighlightView#advance`, and the G rows of `test/editor_syntax.rb` together.
- Also: test/editor_syntax.rb
- Category: editor
- Added: 2026-11-03
