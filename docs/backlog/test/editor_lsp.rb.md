# Backlog: test/editor_lsp.rb

## The published helper's comment in the LSP test is wrapped unevenly

- Where: the comment above `published` in `test/editor_lsp.rb` (line 36 at 38d8c47). Quality advisory at `diagnostics-display`.
- Why it matters: one line runs past 90 columns and the next holds a single word, unlike the rest of the file.
- Fix outline: rewrap it to the file's width.
- Category: ide
- Added: 2026-11-07
