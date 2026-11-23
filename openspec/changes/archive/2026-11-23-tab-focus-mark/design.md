# Design

## Context

`TabBar#paint` read `state.window.buffer` as the selected buffer. With a sidebar focused that is its scratch buffer, `tabless?`, so no tab matched.

## Goals / Non-Goals

**Goals:**
- The file window's tab stays selected while a sidebar has focus; no object per frame on the common path.

**Non-Goals:**
- A focused float; the explorer, winbar, and status bar.

## Decisions

- Reuse `TabPage#side_window?` and `TabPage#editing_leaf`, which `SwitchBuffer` already uses for the file window of a sidebar, instead of a new rule: the mark then names the window `:bn` would switch. Alternative: the first non-scratch leaf, which would disagree with `:bn` after a split.
- Read them only when the current buffer is tabless and no float has focus, so a file window's frame costs one comparison; `side_window?` allocates nothing and `editing_leaf` only in its fallback walk.
- The choice is a private `selected_buffer(state)` of `TabBar`; the overflow anchor and the selection both read it, so the run shown keeps the marked tab.
