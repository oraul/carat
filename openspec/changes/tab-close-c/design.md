# Design

## Context

`SwitchBuffer#call` treats the focused window as a side window when it shows a scratch buffer (`Buffer#scratch?`, an owner set) and no float is focused; it then focuses `TabPage#editing_leaf`, the previous window when it shows a file, else the first file window. `ToggleReading` loads its `[reading]` buffer, owned by `"reading"`, into the window it runs in, as `PinHover` loads its documentation split, so those windows looked like side windows. On a refusal the call ran `tab.focus(side)`, and `TabPage#focus` sets `previous` to the window it leaves, the editing leaf, so the previous window was lost whenever the editing leaf was not it. Plugin side windows open only through `OpenSideWindow`, into one of the tab page's three `Slot`s; `Slot#shown?` already says a slot is shown while its window is a leaf showing a scratch buffer.

## Goals / Non-Goals

Goals: a reading view switches itself, alone or in a split; a refused switch from a side window changes nothing; the flows of `test/editor_tab_flows.rb` type it. Non-goals: `editing_leaf` and the plugin API's `editing_window`, `Quit`'s side-window test, `file_window_count`, floats.

## Decisions

- `Domain::TabPage#side_window?(id)`: whether the leaf id holds the window of a shown slot (`Slot#shown?`), checking the window's identity first so the walk runs only for the slot's own window; no allocation. It is the one place that says what a side window is, beside the slots it reads.
- `SwitchBuffer#call` switches the focused window directly when a float is focused or `side_window?(tab.current)` is false. Only a slot's window goes to the editing leaf.
- On a refusal it writes back the saved `current` and `previous` (the record's writers) instead of calling `focus`, which would record the editing leaf as the previous window. A successful switch keeps the focus in the editing leaf with the side window as its previous window, as before.
- `editing_leaf` keeps preferring windows that show a file: it answers where a side window opens files, for the switch and for plugins, and a reading view is a view of a file, not a place to open another. With only a reading view beside the explorer, a switch from the explorer stays refused, the existing requirement.

## Risks / Trade-offs

- A pinned documentation split now switches itself instead of the file window, like any window that is not a slot's; this matches Neovim, where only the window typed in changes.
- A slot window that a plugin gave a file stops being a side window, as `Slot#shown?` already treats it.
