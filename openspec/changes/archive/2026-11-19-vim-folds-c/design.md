## Context

`Folds` keeps a window's folds flat: parallel first rows, last rows, and closed flags, sorted by first row with the outer fold first, nested by containment. Neovim keeps them as a tree (`fd_nested`), and its foldMoveTo walks that tree level by level from the top. `Motions` holds every motion as a pure function returning a `Motion`; `MotionHandler` registers `Motions::NAMES`. `ChangeFolds` carries out the fold keys by a target symbol.

## Decisions

- The tree is derived from the flat arrays: the parent of fold i is the last fold before it that holds it, since the sort puts every holder before it and the innermost last. `child_holding(parent, row)` and `child_beside(parent, row, forward)` walk one level; with containment nesting, the child beside row is the next or previous sibling of the child holding row, or the nearest child when none holds it, which is what foldMoveTo takes in both of its cases.
- `Folds#next_fold_row(row, forward)` (zj, zk): at each level from the top, the nearest child beside row gives a candidate (its first row forward, its last row backward), a deeper one replacing it; the walk descends into the child holding row and stops at a closed one, so a closed fold counts as one. `Folds#open_fold_row(row, forward)` ([z, ]z): descends through the open folds holding row, the deepest whose edge moves the cursor winning, stopping at a closed fold.
- `Motions.fold_move` repeats the step count times, stopping when a step does not move, and returns nil when none moved; the target is column 0, exclusive charwise, as foldMoveTo sets column 0. The four names join `JUMP_NAMES`, since foldMoveTo calls setpcmark.
- `zR` and `zM` are `ChangeFolds` targets `:open_all` and `:close_all` over new `Folds#open_all` and `Folds#close_all`; `zM` places the cursor as `zc` does. Without a foldlevel option they set every closed flag, which is what Neovim's newFoldLevel does for manual folds.

## Risks

`parent_of` is linear, so a walk is quadratic in the fold count of a window; manual folds number a handful, and nothing calls the walk on a hot path.
