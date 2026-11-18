## Why

Two fold defects left by `vim-folds-a` break Neovim's manual-fold behavior: `zf` at the first row of a larger fold grows the new fold to the larger one, so `zf3jzozfj` leaves rows 0 to 3 folded twice where Neovim nests a fold over rows 0 and 1; and a plugin edit request that fails while applying puts its lines back but leaves the windows' folds where its edits moved, shrank, or dropped them.

## What Changes

- A new fold that starts on the first row of an existing fold and ends inside it nests in it, and one that starts on that row and ends past it holds it, as Neovim's `zf` does; only a fold that truly crosses another (each holding rows the other lacks) grows.
- A plugin edit request that fails after its edits began leaves every window's folds over the buffer exactly as before the request, as it already leaves the lines, the signs, and the marks.
- Roadmap: no new roadmap item; a correctness fix of the manual folds delivered by `vim-folds-a` (section 12, the Vim parity track).
- Out of scope, split by the planner into `vim-folds-windows`: Insert mode opening the cursor's closed fold (`zfjiX`), and a closed split or tab page untracking its windows' folds (`zfj<C-w>s<C-w>c`), with the three backlog headings the brief names.

## Capabilities

### New Capabilities

### Modified Capabilities
- `folds`: `zf` nests a fold at a shared first row; a failed plugin edit leaves the folds as before.

## Impact

- Domain: `Folds#create` counts a fold sharing the new fold's first row as nested, not crossing; `Buffer#transaction_mark` keeps a copy of every tracked fold list and `Buffer#revert_to` puts them back.
- Use cases: none changed; `BufferRequests#edit_buffer` already takes the mark and reverts to it.
- Tests: rows in `test/domain_folds.rb` (`[[2,6],[2,3]]`), `test/editor_folds.rb` (`zf3jzozfj`), and `test/domain_edits.rb` (a reverted edit leaving the folds as before).
- Docs: `docs/compatibility.md` Folding (the nesting at a shared first row), `docs/plugins.md` (`edit_buffer` failure leaves the folds).
- README.md: unchanged, its feature list already names manual folds and nesting is not described there.
- docs/architecture.md: unchanged, it names the window's folds but neither the nesting rule nor the plugin edit rollback.
- Assumptions: an identical fold (same first and last row) still nests as a second fold, as Neovim's `zf` on the same range does; the folds return to their state at the mark, so a fold the failed request dropped comes back closed or open as it was.
