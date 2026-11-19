## Why

Two places disagree with Vim. Insert mode on a closed fold leaves the fold closed, while Vim's foldOpenCursor at insert start opens the folds holding the cursor, so the edited line stays hidden. Closing a window leaves its fold list tracked by the buffer, so every later edit shifts a dead list and `zfj<C-w>s<C-w>c` leaves two fold lists.

## What Changes

- Entering insert or replace mode opens every closed fold holding the current window's cursor (ArrangeView).
- Closing a window or a tab page drops the folds of each closed window, so the buffer stops tracking them (BufferList).
- The other two named places, `layout.rb:229` and `buffer.rb:648`, were read: Layout.close only moves space and Buffer.start_at only sets the undo cursor, and both match Vim, so they are unchanged.

## Impact

- Specs: folds, windows (added scenarios).
- README.md: the fold sentence names insert-mode opening and the close dropping a window's folds.
- docs/compatibility.md: the folds paragraph names insert opening folds.
- docs/architecture.md: unchanged, no layer or port changes.
