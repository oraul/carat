# Proposal

## Why

The architecture review behind the core-quality queue found that `EditorState` is a god object (452 lines on 7cc05e0) holding the buffer list and its keep or release policy, the tab pages with the alternate tab rule and the window ids, the mode, the command line and message, the pending keys and the grammar, the registers and the last find, the plugins' prompt and status segments, `timeoutlen`, the quit flag, cursor upkeep, and showcmd formatting, so every use case can reach everything. The plugin host and the ex runner need each other and are tied together after construction with `attach`; `bin/carat.rb` passes a raw configuration hash and the assembly invents its own fallbacks for the leader and `timeoutlen`; the main loop reads class-level signal flags; `FilePort#stat` returns an untyped hash; the test doubles are compiled into the shipped binary; and 18 files still take positional constructor arguments. `dependency-injection` (PR #19) delivered the input ports and left these to this change, the second and last of the two that deliver the dependency injection the user asked for before more plugins.

## What Changes

This change is outside the roadmap order: it is the fourth change of the core-quality queue the user approved before more plugins ("let's focus on a better carat editor before adding more new plugins"), and it changes how the core is wired, not what it does.

- Split `EditorState` into focused records: `Domain::BufferList` (the listed buffers, their ids, the buffer feed, and the keep or release policy), `Domain::TabList` (the tab pages, the current one, the alternate tab rule, the window ids, and cursor clamping), `Domain::InputState` (the pending keys and the command grammar, owned by `HandleKey`), `Domain::LastFind` (the last `f`, `F`, `t`, or `T`), `Domain::PluginUi` (the plugins' status segments and prompt, the plugin host's own state), and `timeoutlen` as a member of `Options`. The registers stay their own record and leave the state. `EditorState` remains a thin aggregate of the current view (the tab list, mode, options, command line, message, quit flag, pending block insert) with `state.tab`, `state.window`, `state.buffer`, and `state.cursor` working as before.
- Inject each record by keyword into the use cases and adapters that need it, built once in `EditorAssembly`; showcmd formatting moves into `FramePresenter`.
- Drive cursor clamping by the change records of edit-pipeline: when a transaction with records closes on a listed buffer, the buffer feed asks the tab list to keep every cursor on that buffer inside the text, from the first changed row, replacing the three explicit `clamp_cursors` calls.
- Add `UseCases::CommandRunner`, the interface `ExecuteEx` implements; the plugin host receives the runner already built and `PluginHost#attach` and `UiRequests#attach` are removed.
- Inject a real `Ports::ConfigPort` into the assembly: the port gains `source`, `bin/carat.rb` passes the `JsonConfigGateway` and the harness a `FixedConfig`, and the assembly applies no fallback values of its own.
- Add `Ports::SignalPort` with `install`, `terminated?`, `resized?`, and `acknowledge_resize`; `Drivers::Signals` implements it with instance flags, `Doubles::ManualSignals` lets tests trip a resize and a terminate, and `MainLoop` receives the port.
- Make `FilePort#stat` return the `Domain::PathInfo` value, `PathInfo.missing` for a path that does not exist, in the port, the driver, and the memory double; `FileOps#probe` no longer converts a hash.
- Move the test doubles out of the production require graph: `carat.rb` stops requiring `carat/doubles/*`, a new `carat/test_support.rb` requires the library and the doubles for test and benchmark programs, and the lint test refuses a require of a double from anywhere under `bin/` or `carat/` outside `carat/doubles/` and the test-support graph. The backlog entry is removed.
- Convert every constructor on the lint test's pending list to required keyword arguments and remove the pending mechanism.
- Add the shared-instance test: after building the assembly, every collaborator holding the buffer list, the tab list, the registers, the keymap, the plugin host, the command runner, the input state, the plugin UI state, and each port holds the same object.

Out of scope: changing what any key, ex command, or plugin request does; the motions' purity and the last find side effect (the backlog item "Motions take the whole editor state"), apart from the find record they now receive; the `options-and-config` item's user and project files; replacing `call(state, ...)` on the input ports.

Assumptions recorded here rather than asked:

- The change type is `chore` with `skip_specs: true`: no requirement's wording changes. Clamping now also follows edits made in another window of the same buffer (a `dd` of the last line in one split keeps the other split's cursor on a line), which Neovim does as well and no spec states otherwise; it is recorded as a fix inside this refactor.
- `EditorState` stays as the thin aggregate the input ports and the presenter read, because replacing `call(state, command)` on every handler would spread past this change; the buffer list is not part of it, so the use cases that change the list must receive it.
- A configuration value missing from what the port returns falls back to Vim's default in the domain, as `Options.from_config` already does for every option (`timeoutlen` 1000, the leader `\`); the shipped `config/default.json` supplies Carat's own values.
- The input state is shared by `HandleKey` (its owner and only regular writer), `FramePresenter` (showcmd), and the plugin host's prompt request, which drops the pending keys as before.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters no requirement.

## Impact

- Domain: new `buffer_list.rb`, `tab_list.rb`, `input_state.rb`, `last_find.rb`, `plugin_ui.rb`; `editor_state.rb` reduced to the aggregate; `options.rb` (`timeoutlen`), `buffer_feed.rb` (the tab list it reports changes to), `motions.rb` (the find record), `path_info.rb`, `json.rb` (keyword constructors).
- Ports: new `signal_port.rb`; `config_port.rb` (`source`), `file_port.rb` (`stat` returns `PathInfo`).
- Use cases: new `ex/command_runner.rb`; constructors of the file, window, tab, plugin, and editing use cases; `handle_key.rb`, `edit_command_line.rb`, the plugin host and its parts, `files/file_ops.rb`.
- Adapters: `editor_assembly.rb`, `input_controller.rb`, `frame_presenter.rb`, `screen_presenter.rb`, `json_config_gateway.rb`.
- Drivers: `signals.rb`, `main_loop.rb`, `ansi_terminal.rb`, `disk_files.rb`; `bin/carat.rb`.
- Doubles: new `manual_signals.rb`; `fake_terminal.rb`, `memory_files.rb`, `fixed_config.rb`, `editor_harness.rb`; new `carat/test_support.rb`; `carat.rb`.
- Tests: new `domain_buffer_list.rb`, `domain_tab_list.rb`, `drivers_main_loop.rb`, `adapters_assembly.rb`; updated state, buffer, layout, edit, presenter, plugin, and lint tests; every test program that uses a double requires the test-support graph.
- Docs: `CLAUDE.md`, `docs/architecture.md`, `docs/backlog.md`.
- No new dependency, no configuration change, no plugin API change, no change to any key, ex command, or message.
