## Why

Six of Neovim's fold keys are missing: `zR` and `zM`, which open and close every fold, and the fold motions `zj`, `zk`, `[z`, and `]z`, so a user cannot move between folds or unfold a file at once. The single-window branch of `BufferList#close_window` drops the folds of a tab page's kept slot windows, but no test closes a tab page by `:q` on its last window.

## What Changes

- `zR` (`fold.open_all`) opens every fold of the window and `zM` (`fold.close_all`) closes every fold, the cursor going to the first line of the closed fold it is left in; neither gives an error without folds. Bound in normal mode, as `zo` and `zc` are.
- `zj` (`motion.fold_next`) moves to the first line of the next fold and `zk` (`motion.fold_previous`) to the last line of the previous fold, a closed fold counted as one; `[z` (`motion.fold_start`) moves to the first line of the open fold holding the cursor and `]z` (`motion.fold_end`) to its last line, the containing fold's when already there. Each takes a count, goes to column 0, is an exclusive charwise motion under an operator, records a jump, and does nothing where it cannot move, as Neovim's foldMoveTo. Bound in normal, operator-pending, and the three visual modes.
- A test quits a second tab page's only window by `:q` beside a hidden slot window with a fold and sees the buffer's fold lists shrink.

Roadmap: the folding item of `docs/architecture.md` section 12 (Neovim compatibility), continuing vim-folds-a, vim-folds-b, and vim-folds-windows.

Out of scope: `zO`, `zC`, `zA`, `zv`, `zx`, `zn`, `zN`, `zi`, `foldlevel` and the other fold options, `:fold`, `:foldopen`, `:foldclose`, and `zR` or `zM` in visual mode.

Assumptions: Neovim sets no motion type for `zj` and `zk` (an operator keeps the previous command's); they are exclusive charwise here, as `[z` and `]z` are in Neovim. A motion that cannot move gives no message, as Neovim only beeps.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `folds`: zR, zM, and the fold motions zj, zk, [z, ]z.
- `windows`: a scenario for `:q` on a tab page's last window beside a kept slot window with a fold.

## Impact

- Code: `carat/domain/folds.rb`, `carat/domain/motions.rb`, `carat/use_cases/windows/change_folds.rb`, `carat/use_cases/actions/fold_handler.rb`, `config/default.caratrc` and its mirror `carat/domain/default_config.rb`.
- Tests: `test/editor_folds.rb`.
- Docs: `docs/compatibility.md` (rows, the differences paragraph, the jump motions), `docs/actions.md` (six rows).
- README.md: the fold sentence names `zR zM` and the fold motions.
- docs/architecture.md: unchanged, no layer, port, or module changes.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.
