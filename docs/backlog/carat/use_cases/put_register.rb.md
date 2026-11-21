# Backlog: carat/use_cases/put_register.rb

### A linewise put on a closed fold puts the lines inside the fold
- Location: carat/use_cases/put_register.rb:32
- Why: correctness, Neovim parity; a linewise p on a closed fold puts the lines inside the fold, hidden, where Neovim's do_put puts them below the fold's last line (P above its first).
- Fix: for a linewise entry pass the position at folds.last_row(cursor.row) for p, with an editor_folds row proving it.
- Category: editor
- Added: 2026-11-17
