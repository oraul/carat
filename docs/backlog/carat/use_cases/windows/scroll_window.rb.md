# Backlog: carat/use_cases/windows/scroll_window.rb

## A comment block runs to 115 columns

- Where: `carat/use_cases/windows/scroll_window.rb:18`.
- Why it matters: the comment-wrap rule of the block (72 to 75).
- Fix outline: rewrap. Backlog batch: comment wraps.
- Category: editor
- Added: 2026-11-10

### Scrolls step into a closed fold's hidden rows (sprint-16 sweep quality)

- Location: carat/use_cases/windows/scroll_window.rb:64
- Why: line, page, and half-page scrolls move Window#top by buffer rows and never consult the window's Folds, while ArrangeView counts a closed fold as one row, so <C-e>, <C-f>, and <C-d> over a closed fold step into its hidden rows; no test in editor_folds.rb or editor_scroll.rb covers it.
- Fix outline: step the top as j and k do over folds, verified against Neovim, with fold rows in the scroll table test. Pool item `vim-folds-c`.
- Category: editor
- Added: 2026-11-18

### ScrollWindow counts buffer rows past a closed fold at carat/use_cases/windows/scroll_window.rb:85 (sprint-28 sweep quality, note 20)

- Location: carat/use_cases/windows/scroll_window.rb:85; Window#scroll_top_to, max_top; test/editor_scroll.rb
- Why: a closed fold shows as one row, as Window#scroll_folded and ArrangeView count it, but `<C-e>`, `<C-f>`, zz, and zb can put the first shown line inside the fold or past the fold-aware last top and move a visible cursor into it; no folded test case.
- Fix: count screen rows through Folds in page, half, line, place, and keep_in_view, with folded rows in test/editor_scroll.rb.
- Also: test/editor_scroll.rb
- Category: editor
- Added: 2026-11-22
