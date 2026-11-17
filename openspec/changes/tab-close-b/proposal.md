# Proposal

## Why

A user-reported bug, part b of `tab-close` (#178), placed first in Sprint 14 by the user's decision. Under `option.gt buffers`, the default, the top row shows buffer tabs, yet with the focus in a side window (the explorer) `gt`, `gT`, `:bn`, and `:bp` replace the side window's buffer, so the explorer disappears or turns into a second `[No Name]` window. The explorer's `t` opens a Vim tab page while the row shows buffer tabs, so the user ends in tab page 2 swapping buffers in its window. `:tabe` on a file already listed leaves the new tab page's empty buffer listed as a third `[No Name]`. No test types the user's tab flows end to end, so these bugs came back unnoticed.

## What Changes

- Every buffer switch through `SwitchBuffer` (`gt`, `gT` under `option.gt buffers`, `:bn`, `:bp`, `:b N`, `:bfirst`, `:blast`, Ctrl-^, `<leader>bn`, `<leader>bp`, `[b`, `]b`, ...) run with the focus in a side window acts on the tab page's file window, the one the explorer's `editing_window` names (the previous window when it shows a file, else the first file window in layout order), and focuses it; the side window keeps its buffer. With no file window the side window keeps its buffer and the message says "No file window to show the buffer in". (`UseCases::SwitchBuffer`, `Domain::TabPage#editing_leaf`, shared with `WindowRequests#editing_window`)
- A new plugin host request `open_as_tab(path)` opens the file as the top row's tab: under `option.gt buffers` in the editing window as `open_file` does, a buffer tab, the window focused; under `option.gt tabpages`, or with no file window, a tab page as `open_in_tab` does. Plugin API 2.8. (`PluginApi::Host`, `PluginLink`, `WindowRequests`)
- The explorer's `t` calls `open_as_tab`: under `option.gt buffers` the file opens in the file window as a new buffer tab, the previous file staying listed, the focus in the opened file and the explorer kept; on a file already listed it shows that tab. Under `option.gt tabpages` it opens a tab page as before. Its HELP line, action description, `docs/actions.md`, and `docs/plugins.md` say so.
- `:tabe file` and `:tabedit file` on a file already listed show that buffer in the new tab page's window and leave no empty buffer listed; `:tabe` with no name still opens an empty buffer. (`UseCases::OpenTab`)
- A scenario suite, `test/editor_tab_flows.rb`, types the user's opening, moving, and closing flows through `EditorHarness` with the explorer on, started as `carat .`, asserting after every step the top row, the current buffer, the listed buffers, the window and tab page counts, the explorer, the message, and whether the editor quit.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-list`: a buffer switch from a side window acts on the file window.
- `file-explorer`: `t` opens a buffer tab under `option.gt buffers`.
- `tab-pages`: `:tabe` of a listed file leaves no empty buffer listed.
- `plugin-windows`: a plugin opens a file as the top row's tab.

## Impact

- `carat/use_cases/buffers/switch_buffer.rb`, `carat/domain/tab_page.rb`, `carat/use_cases/windows/open_tab.rb`, `carat/use_cases/plugins/window_requests.rb`, `carat/use_cases/plugins/plugin_link.rb`, `carat/plugin_api.rb`, `carat/plugins/explorer/plugin.rb`.
- Tests: `test/editor_explorer.rb`, `test/editor_buffers.rb`, `test/editor_tabs.rb`, the plugin API version rows (`test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`), and the new `test/editor_tab_flows.rb`, with their snapshots.
- README.md: changed, its `gt` and `gT` sentence says that from the explorer they move the file window's buffer tab and that the explorer's `t` opens a buffer tab.
- docs/architecture.md: changed, section 9's window requests name opening a file as the top row's tab (2.8).
- CLAUDE.md: unchanged, no process change.
- docs/codebase-map.md: changed, area 11 names `test/editor_tab_flows.rb`, and the entries of `switch_buffer.rb`, `open_tab.rb`, and `tab_page.rb` where they describe the changed behavior.
- docs/compatibility.md: changed, the `:bnext` family and `:tabedit` rows note the side-window and listed-file behavior. docs/actions.md: changed, the `plugin.explorer.open_tab` row.
- docs/plugins.md: changed, the `open_as_tab` request, the version paragraph, and the explorer's `t`.

Outside the roadmap of `docs/architecture.md` section 12: a user-reported bug fix of Sprint 14's backlog lane.

## Out of scope

- The finder's `<C-t>` keeps calling `open_in_tab` and opening a tab page under both `option.gt` values; making it follow the row is left to a later item, since the user's decision named the explorer's `t`.
- `:bd`, `:q`, and the window commands from a side window keep the rules of `tab-close`.
- A focused float keeps its current behavior for buffer switches.

Minor assumptions: the message with no file window is "No file window to show the buffer in"; a switch refused (E37, E86, E85) leaves the focus in the side window; a new host request rather than a changed `open_in_tab`, so plugins asking for a tab page keep getting one; `open_as_tab` with no file window opens a tab page.
