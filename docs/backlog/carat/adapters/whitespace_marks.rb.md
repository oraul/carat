# Backlog: carat/adapters/whitespace_marks.rb

### Trailing whitespace marks stop at a tab (sprint-24 review and sweep quality)

- Location: `carat/adapters/whitespace_marks.rb:86`
- Why: the trailing run backs up over spaces only, while Neovim's drawline backs over spaces and tabs, so in `a  <Tab>` the two spaces get no trail mark; `docs/compatibility.md` and `test/adapters_whitespace_marks.rb` do not say so.
- Fix: back over 9 and 32 while marking only spaces, with a table row, or list the difference in `docs/compatibility.md`.
- Also: docs/compatibility.md, test/adapters_whitespace_marks.rb
- Category: editor
- Added: 2026-11-21
