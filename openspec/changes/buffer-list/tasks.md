# Tasks

## 1. Planner records

- [x] 1.1 `docs/queue.md` from `build/plan/queue.md`, the entry of `build/plan/backlog.md` and the plan notes' edits of the `:set`, wrap-width, and cursor-line entries in `docs/backlog.md`; verified by `make docs-lint`.

## 2. The keep policy and the remembered cursor

- [x] 2.1 `carat/domain/buffer.rb`: the `last_cursor` member; `carat/domain/buffer_list.rb`: `release` keeps file buffers, `load` keeps the old buffer, reuses the empty startup buffer's number, and restores the cursor, `close_window` and `close_tab` remember the cursor; rows in `test/domain_buffer_list.rb`.
- [x] 2.2 `carat/use_cases/files/save_all.rb`: `E141` with the buffer number, no release loop; `carat/use_cases/windows/close_window.rb` comment; the editor tests whose buffers used to leave the list (`test/editor_windows.rb`, `test/use_cases_ex.rb`, `test/editor_plugins.rb`, and the rest `make test` names) updated to the new rule.

## 3. Buffer list commands

- [x] 3.1 `carat/domain/buffer_list.rb` `step_from`, `first_unsaved`, `bring`, `other_listed?`, `carat/domain/tab_list.rb` `focus_buffer`; rows in `test/domain_buffer_list.rb`.
- [x] 3.2 `carat/use_cases/buffers/list_buffers.rb` (`:ls`, `:buffers`, `:files`, the bang and flags); rows in `test/editor_buffers.rb`.
- [x] 3.3 `carat/use_cases/buffers/buffer_request.rb` and `carat/use_cases/buffers/switch_buffer.rb` (`:bn`, `:bp`, `:bN`, `:b N`); rows in `test/editor_buffers.rb`.
- [x] 3.4 `carat/use_cases/buffers/delete_buffer.rb` (`:bd`); rows in `test/editor_buffers.rb`.
- [x] 3.5 `carat/use_cases/ex/buffer_command_handler.rb`, its wiring in `carat.rb` and `carat/adapters/editor_assembly.rb`; `test/adapters_assembly.rb` holders and `test/use_cases_ex.rb` spellings.

## 4. E162

- [x] 4.1 `carat/domain/messages.rb` (`E37` without the hint, `unsaved_buffer`), `carat/use_cases/files/quit_all.rb` and `carat/use_cases/files/quit.rb` naming and going to the buffer; rows in `test/editor_buffers.rb`, `test/use_cases_ex.rb`, `test/editor_tabs.rb`, `test/editor_cmdline.rb`, `test/editor_windows.rb`.

## 5. Documentation and checks

- [x] 5.1 `docs/compatibility.md` (the rows, `:qa`, `:wa`, the differences), `docs/codebase-map.md` (new files, test, area 11, the delivered change), `docs/architecture.md` (item 7, `BufferList`), `CLAUDE.md` status, `README.md` where it lists commands; `make docs-lint` passes.
- [x] 5.2 `make gates`, `make lint`, `make spec-validate`, `make diagnose`, and `make bench-budget` pass.
