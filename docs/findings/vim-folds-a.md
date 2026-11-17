### A closed window's folds stay tracked and are shifted on every edit
- Location: carat/domain/window.rb:85
- Why: performance; a closed window's Folds stay in its buffer's fold_lists, so every later edit of the buffer keeps shifting dead fold records (named in the change's design risks).
- Fix: untrack the folds when Layout or the tab list removes a window.

### Cursor display column inside a closed fold drifts from the drawn one
- Location: carat/use_cases/arrange_view.rb:107
- Why: correctness; ArrangeView takes the cursor's display column from the line's column even inside a closed fold, while FramePresenter (carat/adapters/frame_presenter.rb:734) uses window.left there, so the scroll and the drawn cursor can disagree.
- Fix: one Window or presenter helper for the cursor's shown column, used by both.

### Layout#close frees a window without untracking its folds
- Location: carat/domain/layout.rb:229
- Why: performance; every later edit of the buffer shifts the dead fold record of the closed window (the design accepts the leak).
- Fix: drop the window's folds where a window is closed, as Window#show does.

### ChangeFolds#place resets want_col where Neovim keeps it
- Location: carat/use_cases/windows/change_folds.rb:44
- Why: correctness; place repeats ArrangeView#to_fold_start (carat/use_cases/arrange_view.rb:137), which now runs after every key, and the two differ on want_col: move_to resets it, while to_fold_start keeps it as Neovim's foldAdjustCursor does.
- Fix: keep one fold-start adjustment, for example a Window#to_fold_start(visual) in the domain that ArrangeView calls, and drop ChangeFolds#place (also drop the move in Operate#fold, carat/use_cases/operate.rb:162).

### A linewise put on a closed fold puts the lines inside the fold
- Location: carat/use_cases/put_register.rb:32
- Why: correctness, Neovim parity; a linewise p on a closed fold puts the lines inside the fold, hidden, where Neovim's do_put puts them below the fold's last line (P above its first).
- Fix: for a linewise entry pass the position at folds.last_row(cursor.row) for p, with an editor_folds row proving it.

### Closing a split or a tab never untracks its windows' folds
- Location: carat/domain/buffer_list.rb:370
- Why: performance and a missing test; a closed window (layout.close, and tabs.remove_tab at line 368) never untracks its Folds, so buffer.fold_lists keeps every closed split's folds and each later splice shifts them.
- Fix: call drop_folds on the closing window (each window of a removed tab) before closing it, and assert fold_lists.length after zfj<C-w>s<C-w>c in test/editor_folds.rb.

### Visual modes do not take in closed folds
- Location: carat/use_cases/arrange_view.rb:138
- Why: correctness; as Neovim's foldAdjustVisual does not happen here, Vd on a closed fold over rows 0 and 1 deletes only row 0 and leaves a one-line fold, and carat/adapters/frame_presenter.rb:829 marks no selection on a fold row, while docs/compatibility.md says a linewise operator starting on a fold acts on all its lines.
- Fix: in a visual mode extend the anchor and cursor rows to the fold edges (first_row of the upper, last_row of the lower), paint the selection on the fold row, and add editor_folds rows such as zfjVd.
### The docs-lint path check fails a delivery that removes a file its own queue entry names (ruby-structure-remove retro)
- Location: `tools/docs_lint.sh:128` (check_paths), over the delivery's own item in `docs/queue-feature.md`
- Why: ruby-structure-remove's check failed in 5 s on 2 removed paths its own queue item named: first.check 0, 1 rework round (a contributor fix start and a second checker start, check 6,950 output tokens over two passes), and the fix's queue edit was discarded by plan-apply; check first pass 142/144.
- Fix: a delivery deleting a file its own queue entry names passes the check on its first pass with no hand edit of a lane queue; accepted when the next such delivery records first.check 1.

### The scout phase runs on a one-area removal whose plan names every location (ruby-structure-remove retro)
- Location: `.claude/workflows/deliver-change.js:184` (scoutTargets)
- Why: ruby-structure-remove's scout spent 33,374 output tokens and 17 calls, 24.6% of 135,491 output tokens and 14.4% of 118 calls, with 1 area, while the plan cited every file and line range and the contributor reversed the earlier diff exactly; scout share over recent feature rows 11.0% to 28.3%.
- Fix: the next one-area removal or revert runs without a scout start, or under 10,000 scout output tokens, keeping first.check, first.quality, and first.security at 1.
