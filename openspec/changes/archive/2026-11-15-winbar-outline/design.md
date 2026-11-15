# Design

## Context

See proposal.md, Why. The symbol request lives in `Domain::SymbolRequest`, shared by the gateway (which asks and reads answers) and the winbar (which reads the held symbols). `stop` already clears `sent_id` through `forget_server`, and an answer from the stopped server's handle is dropped because `by_handle` no longer finds it; what survives `restart` is the record of the text last asked (`asked_buffer`, `asked_changes`, `asked_closed`) and the held symbols, so `send_symbols` never asks the restarted server for the same text and the old outline stays.

The winbar decision is made by `TabPage#winbar?` (the modes), restated by `SplitWindow#winbar_after?` (the modes again, plus the new window), applied per window by `ArrangeView#reserve_winbars` (not scratch, two rows or more), and decided again by `FramePresenter#paint_winbars` (the tab-wide check, not scratch, and the row above the text being the leaf's top).

## Goals / Non-Goals

**Goals:**
- One comparison of the breadcrumbs modes, in `TabPage`.
- One per-window decision, made where the rows are reserved and read where they are painted.
- No symbol held or answered before `:LspRestart` reaches the winbar.

**Non-Goals:**
- Changing when the gateway asks (still while the tab shows winbars) or the other request kinds.

## Decisions

- `SymbolRequest#forget` resets the request in flight, the text last asked, and the held symbols (not the offering languages, which `forget_server` maintains per server). `restart` calls it after `stop`. Alternative: reset the asked record in `forget_server` on every stop and crash; rejected because a crash leaves no server to ask until a restart, and `restart` is the one path that starts a fresh server for the same text.
- `TabPage#winbar_with?(mode, count)` holds the rule (`never` false, `always` true, otherwise two or more file windows); `winbar?(mode)` passes `file_window_count`. `SplitWindow` answers only what it knows, whether the new window shows a file, and asks `winbar_with?(mode, file_window_count + 1)`. A new window that keeps the current window's scratch buffer gets no extra row, which fixes the count under `always` and under `auto` beside two file windows.
- `Window` gets a `winbar` member, false at construction. `ArrangeView` sets it on every leaf at each arrange: true for a file window of two rows or more while the tab shows winbars, false otherwise, giving that window's first row to the winbar as before. `FramePresenter#paint_winbars` paints the windows with the member set and no longer calls `winbar?` or tests scratch. Alternative: a `TabPage#winbar_window?` predicate both call; rejected because the presenter would still re-derive the decision and the reserved geometry separately. ArrangeView runs before every render, so the member is never older than the frame.
- Floats and slot windows keep `winbar` false: floats are not layout leaves and slot windows hold scratch buffers.

## Risks / Trade-offs

- [A window copied or built between an arrange and a render shows no winbar for one frame] → ArrangeView runs after every key, after a file opens, and before every render; a fresh window starts false, the safe side.
- [Allocations per key] → a bool member and one write per leaf per arrange allocate nothing; `lh-winbar` and `lh` in `make bench` confirm.
