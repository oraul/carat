# Proposal

## Why

A user-reported bug, part c of `tab-close` (#178, #181), a regression of `tab-close-b`. `SwitchBuffer` takes any window showing a scratch buffer for a side window, so in a reading view (`<leader>dr`), which loads its `[reading]` scratch buffer into the file window itself, `:bn`, `:bp`, `:b N`, Ctrl-^, and `gt` look for another file window: alone they fail with "No file window to show the buffer in", and beside a split they switch the other window. A switch refused from a side window also rewrites the tab page's previous window, so `<C-w>p` afterwards goes to the window the switch tried rather than the one used before. No test switched from a reading view.

## What Changes

- A side window is known by what it is: a window of the tab page's sidebar or panel slot showing a plugin's view (the explorer), not any window on a scratch buffer. A buffer switch run in any other window, a reading view or a pinned documentation split included, acts on that window, as in a file window. (`Domain::TabPage#side_window?`, `UseCases::SwitchBuffer`)
- A switch refused after focusing the editing window (E37, E86, E85, E23) restores both the tab page's current and previous windows, so nothing changes. (`UseCases::SwitchBuffer`)
- `test/editor_tab_flows.rb` gains flows typing the five commands from a lone and from a split reading view, and a refused switch from the explorer followed by `<C-w>p`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-list`: the side-window switch rule names what a side window is and keeps the previous window on a refusal.

## Impact

- `carat/domain/tab_page.rb`, `carat/use_cases/buffers/switch_buffer.rb`.
- Tests: `test/editor_tab_flows.rb` and its snapshot; a `side_window?` row in `test/editor_breadcrumbs.rb`, beside the file-window count rows.
- README.md: changed, its buffer-tab sentence says a reading view switches its own window, since docs/compatibility.md changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap change, and no section states the buffer-switch rule.
- CLAUDE.md: unchanged, no process change.
- docs/codebase-map.md: changed, the `tab_page.rb` and `switch_buffer.rb` entries.
- docs/compatibility.md: changed, the `:bnext` row says what a side window is and that a reading view switches itself. docs/actions.md: unchanged, no action added or rebound. docs/plugins.md: unchanged, `editing_window` keeps its answer.

Outside the roadmap of `docs/architecture.md` section 12: a user-reported bug fix, Sprint 15 feature lane item 1.

## Out of scope

- `TabPage#editing_leaf` (and the plugin API's `editing_window` sharing it) keeps choosing among windows that show a file: with the explorer beside a lone reading view, a switch from the explorer is still refused with "No file window to show the buffer in", as the existing requirement says.
- `Quit`'s side-window test (`carat/use_cases/files/quit.rb`) and `TabPage#file_window_count` keep their scratch test; neither is named by the reported bug.
- A focused float keeps switching itself, as before.

Minor assumptions: a slot window that took a file (`open_file` into the explorer's window) is no longer a side window, as `Slot#shown?` already says; a pinned documentation split switches itself like a reading view.
