# Tasks

## 1. Ports and the in-memory file system

- [x] 1.1 Add `mkdir`, `rename`, `delete`, and `cwd` to `carat/ports/file_port.rb` and `carat/drivers/disk_files.rb`, and the `symlink` flag (with broken links read as links) to `DiskFiles#stat`; verify with `make build` and `make diagnose` on `bin/carat.rb`
- [x] 1.2 Add `PluginApi::Paths` to `carat/plugin_api.rb` and give `carat/doubles/memory_files.rb` directories, a working directory, entry-name listing, `mkdir`, `rename`, `delete`, and `link`; verify with new rows in `test/use_cases_plugin_files.rb` and the updated listing assertion in `test/use_cases_plugins.rb`

## 2. Host requests

- [x] 2.1 Add `Input`, `FileInfo#symlink`, the eight new `Host` methods, `Plugin#on_input`, and version 1.1 to `carat/plugin_api.rb`, with the forwarding in `carat/use_cases/plugins/plugin_link.rb`; verify `test/domain_plugin_manifest.rb` accepts 1.0 and 1.3 and refuses 2.0 naming 1.1
- [x] 2.2 Implement `working_directory`, `scratch_window`, and `editing_window` in `carat/use_cases/plugins/plugin_host.rb`; verify with `test/use_cases_plugin_files.rb`
- [x] 2.3 Implement `make_file`, `make_dir`, `rename_path`, and `delete_path` with every refusal of the spec, the buffer path rewrite after a rename, and the modified mark after a delete; verify each refusal leaves `MemoryFiles` unchanged in `test/use_cases_plugin_files.rb`
- [x] 2.4 Make `open_scratch` share a buffer shown in another tab page, and `open_file` keep a modified buffer hidden and clear the fixed width of a side window; verify in `test/use_cases_plugin_files.rb` and `test/editor_plugins.rb`
- [x] 2.5 Add the prompt: the fields on `carat/domain/editor_state.rb`, `PluginHost#prompt` and `#answer`, `carat/use_cases/edit_command_line.rb` delivering Enter and cancel, the prompt text in `carat/adapters/frame_presenter.rb`, and the wiring in `carat/adapters/editor_assembly.rb`; verify answer, cancel, backspace cancel, refusal of a second prompt, and "q" Enter not quitting in `test/use_cases_plugin_files.rb`, and the prompt row and cursor in `test/adapters_frame_presenter.rb`

## 3. Window rules

- [x] 3.1 Make `Window#gutter_width` give a scratch buffer no number column in `carat/domain/window.rb`; verify the side window rows in `test/adapters_frame_presenter.rb` and the updated `test/editor_plugins.rb` snapshot
- [x] 3.2 Make `Quit#call` and `Quit#leave` in `carat/use_cases/files/quit.rb` treat the last file window beside side windows as the last window, closing the tab page when others exist; verify `:q`, `:q` refused, `:wq`, `<C-w>q`, the tab page case, and `:q` in the side window in `test/editor_plugins.rb`
- [x] 3.3 Add the `current` icon to `carat/domain/icons.rb`; verify with `test/domain_icons.rb`

## 4. The explorer plugin

- [x] 4.1 Add `carat/plugins/explorer/node.rb`, `file_icons.rb`, and `tree.rb` (listing, ordering, filtering, expand, collapse, reveal, root moves, rendering); verify with `test/plugins_explorer.rb` over a fake host in all three icon sets
- [x] 4.2 Add `carat/plugins/explorer/plugin.rb` with the manifest, toggle, focus, follow, the tree keys, the prompts for create, rename, and delete, and the ex commands; list it in `config/plugins.json` and `config/default.json`, drop `hello` from both, and run `make gen-config`; verify with `test/config_sync.rb` and `test/lint.rb`
- [x] 4.3 Add `test/editor_explorer.rb` over the harness with the registry: every tree key, both ex commands, splits, a tab page, create, rename, delete with confirmation and cancel, `<C-w>=`, `<C-w>h` and `<C-w>l`, quitting with the tree open, and the tree rendered with each icon set; verify it passes against its snapshot
- [x] 4.4 Register `hello` directly in `test/editor_plugins.rb` and adjust its configuration rows; verify the test passes
- [x] 4.5 Open the tree with `<leader>e` in `test/smoke_editor.rb` and quit; verify the smoke test passes

## 5. Documentation and checks

- [x] 5.1 Document the actions in `docs/actions.md`, an explorer section in `docs/compatibility.md`, the new requests and the fixture status of `hello` in `docs/plugins.md`, a "File tree" section in `README.md`, the split of item 12 and the new port methods in `docs/architecture.md`, and Status, Layout, and the test list in `CLAUDE.md`; verify every new action name appears in `docs/actions.md`
- [ ] 5.2 Regenerate the snapshots with `make snapshots`, review the diff, and run `make check`; verify it passes with `make diagnose` clean

## Workflow follow-up

- Run the security review on the committed branch diff, with attention to path traversal in the file requests.
- Archive the change, push, open the pull request, wait for CI, and squash-merge.
