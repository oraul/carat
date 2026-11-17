# Design

## Context

`SwitchBuffer#call` reads `state.buffer` and `BufferList#enter` loads into `tabs.window`, the focused window, whatever it shows. With the explorer focused that is the explorer's scratch window. `WindowRequests#editing_window` already knows the file window a side window works for. `OpenTab` lists a fresh empty buffer before `OpenFile` runs, and `OpenFile` of a listed path enters the listed buffer, leaving the fresh one listed. The explorer's `t` calls `open_in_tab`, which always opens a tab page; a plugin cannot read `option.gt`.

## Goals / Non-Goals

Goals: a buffer switch from a side window changes the file window; the explorer's `t` follows the row; `:tabe` of a listed file leaves no extra buffer; scenario tests type the flows. Non-goals: the finder's `<C-t>`, deleting or quitting from a side window, floats.

## Decisions

- `Domain::TabPage#editing_leaf` returns the leaf the editing window is (previous when it shows a non-scratch buffer, else the first non-scratch leaf in layout order, -1 when none). `WindowRequests#editing_window` and `SwitchBuffer` both use it, so the explorer's notion and the switch's never differ.
- `SwitchBuffer#call`, when the focused layout window shows a scratch buffer and no float is focused, focuses the editing leaf (`TabPage#focus`) before the switch and restores the focus when the switch fails, so a refusal leaves the user where they were. With no editing leaf it fails with "No file window to show the buffer in". All callers (TabHandler, BufferHandler, the `:b` commands) get the rule at once.
- A new Host request `open_as_tab(path)` instead of changing `open_in_tab`: the finder and any plugin asking for a tab page keep getting one, and the explorer, which cannot read `option.gt`, asks the host for "the row's tab". Under `gt_follows_buffers?` it calls `open_file` on the editing window, which already shows a listed path's tab without reopening it, keeps a hidden file listed, and focuses the window; otherwise, or with no editing window, it calls `open_in_tab`. Minor version 2.8.
- `OpenTab` builds the empty buffer without listing it when a path is given; the window shows it while `OpenFile` runs. `OpenFile` then enters the listed buffer, or a new one that takes the next number (the unlisted empty buffer has number 0, so nothing is reused or recorded as alternate), and the empty buffer never reaches the list. When the open fails or leaves the empty buffer shown, it is listed then, as before.

## Risks / Trade-offs

- A refused switch from the explorer keeps the focus there, which differs from a successful one; the message explains it.
- Two host requests that open "a tab" differ by the option; `docs/plugins.md` states which to use.
