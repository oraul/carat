# Proposal

## Why

The architecture and performance review of the plugin host found that a plugin can still end or corrupt the editor, which section 9.4 of `docs/architecture.md` forbids: a plugin error that is not a `StandardError` (an unimplemented host method raises `NotImplementedError`, a runaway recursion raises `SystemStackError`) crashes the editor, a broken manifest crashes startup, a plugin that writes on `buffer_save` recurses until the stack overflows, and a bad last edit item lands half an edit. Events lose changes made by other plugins and carry no range, buffers and windows are addressed by positions that shift, and the host is one 1,085-line class. This is the second change of the core-quality queue the user approved before more plugins, so the finder, git signs, and process plugins build on a host that holds.

## What Changes

This change is outside the roadmap order: it hardens roadmap item 11, `plugin-host`, and the host half of item 12, ahead of `plugin-finder` and item 13, `plugin-protocol`, whose request table it prepares.

- Guard every call into a plugin (registering, reading the manifest, checking it, activating, deactivating, events, actions, ex commands, and input) on one path that catches `StandardError`, `ScriptError`, and `SystemStackError`; a broken manifest registers the plugin disabled instead of ending startup.
- Bound re-entry: while a plugin call is active, events are queued and delivered after the outermost call returns, in rounds with a fixed limit; an ex command a plugin runs that would nest plugin calls beyond a fixed depth is refused with "E169: Command too recursive".
- Give windows stable ids, assigned when a window is created and never reused, and address buffers and windows by id in events, contexts, and every request; `0` still means the current one. Positions stay only for user-facing numbering such as `E141`.
- Validate every item of an edit request (its type and every position) before applying any, inside the plugin edit transaction, and roll the transaction back if applying still fails, so a refused or failed request leaves the buffer unchanged.
- Produce `buffer_change` from closed transactions, for every buffer that changed, with the changed row range (first row, rows removed, rows inserted), including changes another plugin made; add `buffer_close` and `buffer_rename`; keep state comparison only for `cursor_move`, `mode_change`, and `window_focus`. An event a plugin's own request caused is not delivered back to that plugin.
- Copy every string handed across the boundary, in both directions, so a plugin never shares a mutable string with the editor.
- Clean up when a plugin is disabled, also when `activate` raises: close the windows of its scratch buffers, clear its signs, cancel its prompt, and remove its key bindings, which the keymap now records with their owner.
- Tighten the manifest rules: refuse a different major API version and a newer minor version than the host's, refuse a second plugin with a registered name or an ex command another plugin declared, and report a default binding that conflicts with another plugin's.
- Keep signs per buffer, one per row per plugin, as row-indexed data moved with inserted and deleted lines by the change records; when two plugins mark one row, the plugin registered first shows.
- Lint plugin files for references to the editor's layers (`Domain::`, `UseCases::`, `Adapters::`, `Drivers::`, `Doubles::`), check that the plugin link overrides every host method, and teach the lint test the concern directories.
- Change the API boundary: string enums instead of symbols for events, option types, and sides; typed responses for the window requests and for `icon`, `option`, and `working_directory`; new `open_in_split` and `open_in_tab` requests, which the explorer uses instead of building ex command strings, so a path with a space or a `|` opens correctly. The API version becomes 1.2.
- Split the host into small classes by request family under `carat/use_cases/plugins/`, with a `Guarded` concern under `carat/use_cases/concerns/`, a domain `PathPolicy`, and a `FileOps` use case that the file requests delegate to; side windows go through a side-window variant of `SplitWindow`. `open_file` opens before it moves focus, and plugins activate after the ex command runner is attached, so `run_ex` works in `activate`.
- Update `docs/plugins.md`, `docs/architecture.md` section 9, `CLAUDE.md`, and remove the backlog entry on signs.

Out of scope: the JSON-RPC gateway and the process plugin protocol (item 13); removing `attach` (the dependency-injection change); a typed `FilePort#stat` (the dependency-injection change); the selection request and the unfocused tree cursor (backlog entries that stay); the `idle` event.

Assumptions recorded here rather than asked:

- The version becomes 1.2, a minor bump as asked, although some changes are not purely additive (ids in the fields that held positions, string enums, typed responses for five requests, `BufferView#buffer` in place of `number`). The only plugins are in this repository and move with it; a 1.1 manifest that lists events or option types as symbols is still accepted and converted.
- A window id addresses a window in any tab page: focusing or opening a file in a window of another tab page makes that tab page current, as Neovim's `win_gotoid` does.
- An event a plugin's own request caused (a change, a save, an open, a close, or a rename) is not delivered to that plugin; a transaction that mixes a plugin's edits with the user's, such as an insert session a plugin edited during, counts as the user's and goes to every plugin.
- `buffer_change` is delivered when a transaction closes, so an insert session reports its change when insert mode is left, not on every typed character.
- Events queued during plugin calls are delivered in rounds; after 8 rounds the rest are dropped with a message, and an ex command run from a plugin call nested 4 deep is refused.
- A broken manifest that raises registers the plugin disabled under the name `plugin<N>`, its position in the plugin list.
- When disabling a plugin closes the last window of the editor, that window shows a new empty buffer instead.
- Of two plugins binding the same keys by default, the first registered keeps the binding and the conflict is reported for the second.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: guarded calls with the broader error classes and manifest failures, the version rules, duplicate names and commands, binding conflicts, ids instead of positions, events from transactions with ranges, close and rename events, events caused during plugin calls, re-entry limits, edit item validation, signs that move with lines and keep a fixed priority, strings copied at the boundary, cleanup on disable, typed responses, and `run_ex` during activation.
- `plugin-windows`: windows addressed by id across tab pages, opening a file before focusing, and the `open_in_split` and `open_in_tab` requests.
- `file-explorer`: files with a space or a `|` in their name open in a split and in a tab page.

## Impact

- API: `carat/plugin_api.rb` (version 1.2, string enums, ids, `Event` ranges, `WindowResponse`, `TextResponse`, `BufferView#buffer` and `message`, `open_in_split`, `open_in_tab`).
- Domain: `buffer.rb` (sign layers, the feed, `rename`, rollback), `transaction.rb` (cause and range), new `buffer_feed.rb`, `buffer_notice.rb`, `sign_layer.rb`, `path_policy.rb`, `path_info.rb`, `line_splice.rb` (the integer sibling), `window.rb` and `editor_state.rb` (window ids), `layout.rb`, `tab_page.rb`, `keymap.rb` (owners, `action_name?`), `manifest_check.rb`.
- Use cases: `carat/use_cases/plugins/` split into the host facade, registry, entries, router, events, and four request families, `plugin_link.rb`; new `concerns/guarded.rb` and `files/file_ops.rb`; `windows/split_window.rb`, `windows/open_tab.rb`, `files/save_file.rb`, `files/execute_ex.rb`, `handle_key.rb`; the adapters' `editor_assembly.rb` and `frame_presenter.rb`.
- Plugins: `carat/plugins/explorer/plugin.rb` and `tree.rb`, `carat/plugins/hello/plugin.rb`.
- Tests: a new `test/use_cases_plugin_hardening.rb`, updates to the plugin, explorer, buffer, layout, manifest, and presenter tests, and new rules and self-checks in `test/lint.rb`.
- Docs: `docs/plugins.md`, `docs/architecture.md`, `docs/backlog.md`, `CLAUDE.md`.
- No new dependency and no configuration change.
