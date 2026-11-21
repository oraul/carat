# Tasks

## 1. Keys and the port

- [x] 1.1 `Key::SHIFT_TAB`, `KeyDecoder` (`ESC [ Z`) and `encode`, key notation `<S-Tab>` (proved by `test/adapters_key_decoder.rb` and `test/domain_keys.rb` "Shift-Tab decodes to its own key")
- [x] 1.2 `FilePort#list_first`, `DiskFiles#list_first` with `Dir#read` stopping at the limit, `MemoryFiles#list_first` (proved by `test/drivers_disk_files.rb` "list_first reads at most the limit")

## 2. Completion

- [x] 2.1 `Domain::CmdlineMenu` record and `CloseCmdlineMenu`, `HandleKey#follow` closing a stale menu, `NormalModeHandler` closing it on `<Esc>` first (proved by `test/editor_cmdline_complete.rb` "Escape closes the menu first", "Typing closes the menu")
- [x] 2.2 `CompleteCommandLine`: command names, paths, the bound, cycling, the popup (proved by `test/editor_cmdline_complete.rb`, every scenario of the delta spec)
- [x] 2.3 `CommandLineCompleteHandler` registering `cmdline.complete_next` and `cmdline.complete_previous`, the keymap lines, `make gen-config`, the wiring in `EditorAssembly`

## 3. Docs

- [x] 3.1 README, `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, the `FilePort` row of `docs/architecture.md` section 6
- [x] 3.2 `bench/keys.rb` scenario `cmdline-tab`, the popup stepped by `<Tab>` and `<S-Tab>` (measured by `bench/run.sh --budget cmdline-tab 100`: 79.5 objects per key, under the cursor scenario's budget of 100; `lh` holds 25.0)
