# Design

## Context

`TabBar#paint` filled row 0 from column 0 and wrote each tab with a trailing `│`. `ArrangeView` reserved the first row of every shown slot window for a header and the presenter painted the slot's view titles there in `TabLineFill`. `paint_row` drew `~` for every row past a window's text.

## Goals / Non-Goals

**Goals:**
- No tab separator; the tab row from the editor's first column; the sidebar headed by `carat · main` with no extra title row; no tilde in a sidebar.

**Non-Goals:**
- The accent and fill of the tabs, the focus mark, the design doc's drift table, the right sidebar and the panel.

## Decisions

- `Slot#headed?(tab_row)` is the one decision of whether a slot window gives up its first row, read by `ArrangeView#reserve_headers` and implied in the presenter by the window's row against its layout row. It is true for every slot but the left sidebar; the left sidebar is headed with two views or without a tab row. Alternative: dropping the row for every slot with one view, which would remove the title the right sidebar and the panel have no other place for.
- With no tab row the left sidebar keeps its first row and paints the head there, so a single open file still shows the project and branch; with a tab row the head stands on row 0 and no row is reserved. Alternative: no head without a tab row, which leaves the sidebar untitled in the common state.
- The head is painted by `TabBar#paint_head`, which owns the row's look, with plain groups lifted by `Frame#lift` onto the sidebar layer. It takes the branch as an argument and reads the project from `BufferList#base`, set to the working directory at startup, so `TabBar` gains no collaborator. The groups are `Normal`, `NonText`, and `MsgDim`; no group is added, so no group id moves.
- The tab row's start is computed by `FramePresenter#paint_tab_head` from the left slot's window (`col + width + 1`), which also paints the head and returns the column; `TabBar#paint` clamps it to the row and keeps the tab-page numbers at or after it.
- A sidebar window's rows past its text use `PaintedRows::BLANK`, a sentinel compared by identity like `TILDE`, so the row cache needs no new input and a window that changes between sidebar and editor already changes its layer.
