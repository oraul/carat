# Tasks

## 1. Keys and the port

- [ ] 1.1 `Key::SHIFT_TAB`, `KeyDecoder` (`ESC [ Z`) and `encode`, key notation `<S-Tab>` (proved by `test/adapters_key_decoder.rb` and `test/domain_keys.rb` "Shift-Tab decodes to its own key")
- [ ] 1.2 `FilePort#list_first`, `DiskFiles#list_first` with `Dir#read` stopping at the limit, `MemoryFiles#list_first` (proved by `test/drivers_disk_files.rb` "list_first reads at most the limit")

## 2. Completion

- [ ] 2.1 `Domain::CmdlineMenu` record and `CloseCmdlineMenu`, `HandleKey#follow` closing a stale menu, `NormalModeHandler` closing it on `<Esc>` first (proved by `test/editor_cmdline_complete.rb` "Escape closes the menu first", "Typing closes the menu")
- [ ] 2.2 `CompleteCommandLine`: command names, paths, the bound, cycling, the popup (proved by `test/editor_cmdline_complete.rb`, every scenario of the delta spec)
- [ ] 2.3 `CommandLineCompleteHandler` registering `cmdline.complete_next` and `cmdline.complete_previous`, the keymap lines, `make gen-config`, the wiring in `EditorAssembly`

## 3. Docs

- [ ] 3.1 README, `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`
