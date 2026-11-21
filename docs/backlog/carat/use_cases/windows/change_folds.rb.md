# Backlog: carat/use_cases/windows/change_folds.rb

### ChangeFolds#place resets want_col where Neovim keeps it
- Location: carat/use_cases/windows/change_folds.rb:44
- Why: correctness; place repeats ArrangeView#to_fold_start (carat/use_cases/arrange_view.rb:137), which now runs after every key, and the two differ on want_col: move_to resets it, while to_fold_start keeps it as Neovim's foldAdjustCursor does.
- Fix: keep one fold-start adjustment, for example a Window#to_fold_start(visual) in the domain that ArrangeView calls, and drop ChangeFolds#place (also drop the move in Operate#fold, carat/use_cases/operate.rb:162).
- Also: carat/use_cases/arrange_view.rb, carat/use_cases/operate.rb
- Category: editor
- Added: 2026-11-17
