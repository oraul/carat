# Tasks

## 1. Domain records

- [x] 1.1 Add `Domain::TabList` and `Domain::BufferList` (moving the tab, window id, buffer list, id, feed, and release code out of `EditorState`), `Domain::InputState`, `Domain::LastFind`, and `Domain::PluginUi`; add `timeoutlen` to `Options` with `from_config` over the whole value and `Keymap.leader_from`; reduce `EditorState` to the aggregate; verify with the new `test/domain_buffer_list.rb` and `test/domain_tab_list.rb` and the moved cases of `test/domain_layout.rb`, `test/domain_edits.rb`, and `test/domain_buffer.rb`
- [x] 1.2 Make `BufferFeed` report each change notice to the tab list's `clamp_cursors` and remove the explicit clamp calls; verify with the clamp cases in `test/domain_tab_list.rb` and the unchanged `test/editor_windows.rb` and plugin snapshots
- [x] 1.3 Give `Motions.for_command` the `LastFind` record; verify with `test/editor_motions.rb`

## 2. Ports, drivers, and doubles

- [x] 2.1 Make `FilePort#stat` return `Domain::PathInfo` in the port, `DiskFiles`, and `MemoryFiles`, and drop `FileOps`'s conversion; verify with `test/use_cases_plugin_files.rb` and `test/plugins_explorer.rb`
- [x] 2.2 Add `ConfigPort#source` to `JsonConfigGateway` and `FixedConfig`; verify with the configuration tests in `test/editor_plugins.rb`
- [x] 2.3 Add `Ports::SignalPort`, turn `Drivers::Signals` into its driver, add `Doubles::ManualSignals`, and give `MainLoop` the port; verify with the new `test/drivers_main_loop.rb`
- [x] 2.4 Move the doubles out of `carat.rb` into `carat/test_support.rb` and require it from the test programs; verify with `make build` and `make test`

## 3. Use cases and adapters

- [x] 3.1 Add `UseCases::CommandRunner`, make `ExecuteEx` implement it, give the plugin host and `EditCommandLine` the runner, and remove both `attach` methods; verify with `test/use_cases_plugins.rb` (run_ex) and `test/editor_cmdline.rb`
- [x] 3.2 Inject the buffer list, tab list, registers, last find, input state, and plugin UI state into the use cases, the plugin host and its parts, `HandleKey`, `InputController`, and `FramePresenter` (showcmd formatting moves there), with keyword constructors for every file on the pending list; verify with every editor and use case test, snapshots unchanged
- [x] 3.3 Rewire `EditorAssembly` over the config port with readers for every collaborator, update `EditorHarness` and `bin/carat.rb`; verify with `make build` and the smoke test

## 4. Tests, lint, and documentation

- [x] 4.1 Add the shared-instance test `test/adapters_assembly.rb`; verify that it passes and that it fails when one collaborator is given a second object
- [x] 4.2 Add the double-require rule to `test/lint.rb` with its self-checks and remove the pending constructor list; verify with `make lint`
- [x] 4.3 Update `CLAUDE.md` (Status, Layout, ports, Stack, conventions), `docs/architecture.md` (entities, ports table, composition root, test-support graph, tests), and `docs/backlog.md` (remove the doubles entry, update the motions entry); verify by reading them against the code

## 5. Verification

- [ ] 5.1 Run `make check` and `make types` (no member of the new records widens), and the key benchmark against `main` for `keys lh 2000 10000`, `keys i 2000 10000`, and `keys dd 2000 100000`, pinned to one core with interleaved runs, recording the result in the design; verify key handling stays within 10 percent

## Workflow follow-up

- Run the security review on the committed branch, archive the change with `--skip-specs`, and open, check, and merge the pull request.
