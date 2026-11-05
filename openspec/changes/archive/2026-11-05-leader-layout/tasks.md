# Tasks

## 1. Action descriptions

- [x] 1.1 `carat/use_cases/actions/action_table.rb`: `register(name, handler, description)` and `describe(name)`; every core handler's `register` under `carat/use_cases/actions/` passes a description per name; the `make new-action` template in `tools/new.sh` passes one; rows in `test/use_cases_actions.rb` (a registered name's description, an unknown name's empty one, every core action described in 1 to 32 characters); verified by `make test-one T=test/use_cases_actions.rb` and `make tools-test`.

## 2. File and quit actions

- [x] 2.1 `carat/use_cases/actions/file_handler.rb` (`file.save`, `file.find`, `quit.all`, `quit.write_all`) from `make new-action`, wired in `carat.rb` and `carat/adapters/editor_assembly.rb`; `docs/actions.md` rows (`file.find` under Reserved); the handler gets the one `SaveFile`, `SaveAll`, and `QuitAll` the ex commands use; verified by `make test-one T=test/use_cases_actions.rb` (every handler returns an `Outcome`, the table matches `docs/actions.md`).

## 3. Buffer actions

- [x] 3.1 `carat/use_cases/actions/buffer_handler.rb` (`buffer.list`, `buffer.next`, `buffer.previous`, `buffer.delete`) from `make new-action`, wired in `carat.rb` and `carat/adapters/editor_assembly.rb`; `docs/actions.md` rows; the handler gets the one `ListBuffers`, `SwitchBuffer`, and `DeleteBuffer` the ex commands use; verified by `make test-one T=test/use_cases_actions.rb` (every handler returns an `Outcome`, the table matches `docs/actions.md`).

## 4. The leader layout and Ctrl-S

- [x] 4.1 `config/default.caratrc`: remove `<leader>w :w<CR>` and `<leader>q :q<CR>`, add the window, quit, file, and buffer groups and `<C-s>` in normal and insert mode; `make gen-config` regenerates `carat/domain/default_config.rb`; verified by `make test-one T=test/config_sync.rb`.
- [x] 4.2 `test/editor_leader.rb` (new, table-driven): a row per new binding, the old keys no longer writing or quitting, Ctrl-S in insert mode staying in insert mode, and Ctrl-S as the raw byte 0x13; verified by `make test-one T=test/editor_leader.rb`.
- [x] 4.3 The tests of the moved keys: `test/domain_keymap.rb` (leader w a prefix, leader ws the split), `test/editor_normal.rb` (a user replay binding writes), `test/editor_cmdline.rb` (leader qq quits); verified by `make test-one` on each.
- [x] 4.4 `test/smoke_editor.rb`: Ctrl-S in insert mode writes the file over a pseudo-terminal and `<leader>qq` quits; verified by `make test-one T=test/smoke_editor.rb` after `make build`.
- [x] 4.5 `carat/use_cases/handle_key.rb`: a key-sequence value resolved after `timeoutlen` replays (the timeout's queue returned and assigned); verified by the user-binding row of `test/editor_normal.rb`.

## 5. Documentation and checks

- [x] 5.1 `README.md` (the leader layout, Ctrl-S, what moved and what to press instead, the held-Ctrl window keys named as bound), `docs/codebase-map.md` (the new files and tests), `docs/backlog.md` (the held-Ctrl README entry removed); verified by `make docs-lint` and `make gates`.
- [x] 5.2 `make lint`, `make diagnose`, `make bench-budget`, `make spec-validate`, and `make gates` pass.
