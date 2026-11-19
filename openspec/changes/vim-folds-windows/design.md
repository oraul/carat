## Context

ArrangeView skips the closed-fold cursor adjustment while typing so the insert cursor may sit inside a fold; nothing opened the fold. BufferList.close_window and close_tab removed windows without calling Window#drop_folds, the only caller of untrack_folds besides zd.

## Decisions

- Open folds in ArrangeView, which runs after every key, for the current window only while the mode is insert or replace: `open_at` is repeated while `closed_at` finds a closed fold, since nested closed folds open outermost first. Vim does this once at insert start; running per key is equivalent because only a closed fold can reappear by an explicit fold command, which cannot run in insert mode.
- Drop folds in BufferList before the window leaves the layout, so a split's other window keeps its own list.

## Risks

None known; `o` and `O` put the cursor outside the fold, so they are unchanged.
