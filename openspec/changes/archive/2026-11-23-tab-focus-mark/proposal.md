# Proposal

## Why

With the explorer focused no buffer tab is marked: `TabBar#paint` selects the tab of `state.window.buffer`, which under a focused sidebar is the scratch tree buffer, and a scratch buffer has no tab. The row reads as if no file were open, although the file window is still showing one. The queue entry (`tab-focus-mark`, the user's request after the tabs council) asks that the file window's tab stay marked while a sidebar has focus.

## What Changes

- `TabBar#paint` selects the tab of the buffer in the editing window when a sidebar has focus: `TabPage#editing_leaf`, the window `SwitchBuffer` already treats as the file window of a sidebar, read only while the current window is a side window (`TabPage#side_window?`), so every other frame keeps the current window's buffer and the common path allocates nothing.
- A focused float keeps `state.window`, as before.
- The class comment of `TabBar` says it.
- Add a `buffer-tabs` scenario and a row in `test/adapters_tab_bar.rb` that focuses a side window and expects the file's tab in `TabLineSel`, failing before the change.

Out of scope: a focused float such as the finder is also `state.window`; whether the mark holds under a float is not asked. The explorer's own highlighting, the winbar, and the status bar are unchanged.

Roadmap: outside `docs/architecture.md` section 12 (a fix of the delivered buffer tabs, queued in `docs/queue-feature.md`).

Assumptions: with no editing window (`editing_leaf` is -1) no tab is marked, as before; the fallback walk of `editing_leaf` allocates only while a sidebar is focused and the previous window is not a file window, which a frame in that state rarely meets.

## Capabilities

### New Capabilities

### Modified Capabilities
- `buffer-tabs`: the selected tab stays that of the file window while a sidebar has focus.

## Impact

- Code: `carat/adapters/tab_bar.rb`.
- Tests: `test/adapters_tab_bar.rb`.
- Docs: README.md (the buffer tabs sentence), `docs/codebase-map.md` (the tab bar line).
- docs/architecture.md: unchanged, it names the tab bar as a part and describes no selection rule.
