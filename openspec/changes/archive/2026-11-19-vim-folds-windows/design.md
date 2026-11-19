## Context

ArrangeView skips the closed-fold cursor adjustment while typing so the insert cursor may sit inside a fold; nothing opened the fold. BufferList.close_window and close_tab removed windows without calling Window#drop_folds, the only caller of untrack_folds besides zd.

## Decisions

- Open folds with `Window#open_cursor_folds`, repeated `open_at` while `closed_at` finds a closed fold, since nested closed folds open outermost first. Vim does this once in edit() at insert start, redo included. ArrangeView calls it for the current window while the mode is insert or replace, which covers every insert-entering key; RepeatLast calls it before typing a replayed insert, which enters and leaves insert with no arrange between (`zfjiX<Esc>zc.`).
- Drop folds in BufferList before the window leaves the layout, so a split's other window keeps its own list; closing a tab page also drops the folds of its kept slots' hidden view windows.

## Risks

None known; `o` and `O` put the cursor outside the fold, so they are unchanged.
