# Tasks

## 1. Entities

- [x] 1.1 Add `carat/domain/position.rb`, `range.rb`, `cursor.rb`, and `buffer.rb` with the four primitives, line-ending detection, and `from_text`/`to_text`; verify with `test/domain_buffer.rb`
- [x] 1.2 Add `carat/domain/key.rb` and `key_notation.rb` (parse with leader, format, error reporting); verify with `test/domain_keys.rb`
- [x] 1.3 Add `carat/domain/mode.rb`, `options.rb`, and `keymap.rb` (trie per mode from the config, lookup kinds, errors); verify with `test/domain_keymap.rb` against `config/default.json`
- [x] 1.4 Add `carat/domain/ex_command.rb` and `ex_grammar.rb`; verify with `test/domain_ex_grammar.rb`
- [x] 1.5 Add `carat/domain/cell.rb`, `frame.rb`, `highlight.rb`, `window.rb`, and `editor_state.rb`; verify they build through `carat.rb` and are exercised by `test/adapters_frame_presenter.rb` in task 4.1

## 2. Ports and doubles

- [x] 2.1 Add `carat/ports/terminal_port.rb`, `clock_port.rb`, `file_port.rb`, and `config_port.rb` raising `NotImplementedError`; verify with `spin build` and `test/lint.rb`
- [x] 2.2 Add `carat/doubles/fake_terminal.rb`, `manual_clock.rb`, `memory_files.rb`, and `fixed_config.rb`; verify through the editor tests in task 6

## 3. Use cases

- [x] 3.1 Add `carat/use_cases/move.rb`, `enter_insert.rb`, `insert_text.rb`, `leave_insert.rb`, and `show_message.rb` implementing the normal-mode and insert-mode specs; verify with `test/editor_normal.rb` and `test/editor_insert.rb`
- [x] 3.2 Add `carat/use_cases/files/open_file.rb`, `save_file.rb`, `quit.rb`, `execute_ex.rb`, and `edit_command_line.rb` with Vim's messages for E32, E37, E212, E492, the written message, and the opened message; verify with `test/use_cases_ex.rb`
- [x] 3.3 Add `carat/use_cases/dispatcher.rb` and `handle_key.rb` with pending keys, timeout resolution, remap replay with a depth cap, and the "Not implemented" message; verify with `test/editor_normal.rb` (prefix, timeout, leader, dd)

## 4. Adapters

- [x] 4.1 Add `carat/adapters/frame_presenter.rb` painting gutter, text, tilde rows, status line, and message row with scrolling, tabs, and wide characters; verify with `test/adapters_frame_presenter.rb`
- [x] 4.2 Add `carat/adapters/screen_presenter.rb` with full and row-diff writes, cursor shape, enter and leave sequences; verify with `test/adapters_screen_presenter.rb`
- [x] 4.3 Add `carat/adapters/key_decoder.rb` with UTF-8, CSI and SS3 sequences, lone Escape, Alt, and `encode`; verify with `test/adapters_key_decoder.rb`
- [x] 4.4 Add `carat/adapters/input_controller.rb` and `json_config_gateway.rb`; verify with `test/editor_cmdline.rb` (timeout path) and `test/editor_screen.rb` (resize)

## 5. Drivers and entry point

- [x] 5.1 Add `carat/drivers/ansi_terminal.rb`, `disk_files.rb`, `monotonic_clock.rb`, and `main_loop.rb`; verify with `spin build` and `make diagnose`
- [x] 5.2 Rewrite `bin/carat.rb` as the composition root with argument checking, the terminal check, signal traps, the raw block, and cleanup; update `carat.rb`'s require graph; verify with `test/smoke_editor.rb` (usage, non-terminal, insert-write-quit, SIGTERM) and add `build` as a prerequisite of `make test`

## 6. Editor harness and whole-editor tests

- [x] 6.1 Add `carat/doubles/editor_harness.rb`; verify with `test/editor_normal.rb`, `test/editor_insert.rb`, `test/editor_cmdline.rb`, and `test/editor_screen.rb` covering every scenario of the normal-mode, insert-mode, command-line-mode, keymap-config, and screen-rendering specs

## 7. Documentation

- [x] 7.1 Add `docs/compatibility.md` listing every Neovim command implemented with its test, and `docs/actions.md` listing the action names `HandleKey` dispatches; verify each listed command has a row in a table-driven test
- [x] 7.2 Update `CLAUDE.md` Status, Commands, and Layout and the README to describe the editor that now exists; verify every listed command runs as written

## 8. Integration

- [x] 8.1 Run `make check` (build, gen-config, test, diagnose) and `make snapshots` for new tests; verify everything passes and the snapshot diff is reviewed

## Workflow follow-up

- Archive the change, then open the pull request and squash-merge it after CI is green.
