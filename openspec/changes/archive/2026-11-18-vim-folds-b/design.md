## Context

`Folds#create` (`carat/domain/folds.rb`) grows a new fold over every fold it crosses. Its test counts a fold starting on the new fold's first row and ending past its last as crossing, so a fold nested at a shared first row grows to the outer one. `Buffer#splice` shifts every tracked fold list (`fold_lists`) with each edit; `Buffer#revert_to`, which `BufferRequests#edit_buffer` calls after `transaction_mark` when applying a validated request still raises, splices the lines back and shifts the signs, syntax cache, and global marks back, but not the folds.

## Goals / Non-Goals

**Goals:**
- Nesting at a shared first row, as Neovim's `foldCreate` descends into a fold that holds the whole new range.
- A reverted plugin edit leaves the folds exactly as at the mark, a fold a deletion shrank or dropped included.

**Non-Goals:**
- Undo (`u`) restoring folds: Neovim does not, and `editor_folds` already pins that.
- The rest of `vim-folds-b`, split to `vim-folds-windows` (proposal).

## Decisions

- Crossing test: a fold crosses the new range only when it starts strictly inside it and ends past it, or starts before it and ends inside it before its last row. A fold at the same first row is then either inside the new range (the new one holds it) or holding it (the new one nests), and the existing insertion order already sorts the outer one first at one first row. Alternative: keep the test and special-case equal first rows after the loop; rejected as two rules for one relation.
- Fold rollback by a copy at the mark: `transaction_mark` copies every tracked fold list (`Folds#copy_from`) beside the list itself, and `revert_to` copies them back after reverting the records, then forgets them. Alternative: shift the folds back by the inverse of each record, as the signs and marks are; rejected because a deletion that shrank or dropped a fold cannot be undone by an insertion, so the folds would not be "as before". The copy costs nothing when no window has a fold (the common case: `fold_lists` empty) and one copy per folded window per plugin edit otherwise.
- The copy lives in `Buffer`, not in `BufferRequests`, so `revert_to` keeps one meaning (back to the mark) for every caller and the use case is unchanged.

## Risks / Trade-offs

- [A caller reverting without a fresh mark restores an older copy] → `transaction_mark` replaces the copy each time and `revert_to` forgets it after use; the only production caller takes the mark right before applying. A caller using `transaction_size` as the count, as two tests do, finds no copy and leaves the folds where the reverted records leave them.
- [A fold list untracked between mark and revert] → the copy is matched to the list object it was taken from, so restoring writes into that window's own record and never into another's.
