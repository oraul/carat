# Backlog: carat/use_cases/ex/tab_command_handler.rb

## Ex commands that take no argument ignore one

- Where: `carat/use_cases/ex/tab_command_handler.rb:38` (`:tabn 3`), `file_command_handler.rb:41` and `:45` (`:q x`, `:qa x`), `window_command_handler.rb` (`:close x`, `:only x`), `history_command_handler.rb:44` and `:45` (`:redo x`, `:undolist x`).
- Why it matters: Neovim refuses with E488; `:tabn N` acts though `docs/compatibility.md:446` says it is not implemented.
- Fix outline: one ExHandler helper answering E488 as LspStart does, Not implemented for `:tabn N`, table rows in `use_cases_ex`. Queue item `buffer-list-tidy`.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-10

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:101

- Why: duplication, architecture section 5 (logic several use cases share moves into the domain): digits? is the third copy, beside BufferCommandHandler#digits? and HistoryCommandHandler.digits?.
- Fix: move one digits? into a domain helper and call it from the three ex handlers.
- Category: editor
- Added: 2026-11-12

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:71

- Why: the magic args.bytesize <= 9 is repeated at :82 and mirrors BufferCommandHandler#number_in's own 9-digit cut.
- Fix: one shared number-argument helper (or a named constant) that both handlers use.
- Category: editor
- Added: 2026-11-12

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:45

- Why: duplication: a sixth inline "E488: Trailing characters" literal while this change moved E475 into Messages.invalid_argument.
- Fix: add Domain::Messages.trailing_characters(text) and use it here and in the other ex handlers.
- Category: editor
- Added: 2026-11-12

### Three ex handlers spell digits? apart

- Location: carat/use_cases/ex/tab_command_handler.rb:102, buffer_command_handler.rb:102, history_command_handler.rb:67 (sweep, quality).
- Why: three copies of one check.
- Fix outline: one domain predicate the three call.
- Category: editor
- Added: 2026-11-17

### Handlers repeat small helpers (sprint-18 sweep quality)
- Location: `carat/use_cases/ex/tab_command_handler.rb:102`, `buffer_command_handler.rb:102`, `history_command_handler.rb:61`, `carat/domain/json.rb:72` (`digits?` four times); `carat/use_cases/search/global_command.rb:82` and `substitute_lines.rb:112` (`remember`); `carat/domain/keymap.rb:321` (`name_group` repeats `bind_text`, `:200`); `carat/adapters/input_controller.rb:134`; `carat/use_cases/files/save_all.rb:33`.
- Why it matters: copies change apart.
- Fix outline: one domain digit predicate, one shared pattern-recording step, one keymap parse helper, one handle call, one branch.
- Also: carat/domain/json.rb, carat/use_cases/search/global_command.rb, carat/domain/keymap.rb, carat/adapters/input_controller.rb, carat/use_cases/files/save_all.rb
- Category: editor
- Added: 2026-11-18

### Carat/use_cases/ex/buffer_command_handler.rb (sprint-20 sweep quality, tab_command_handler.rb:102,)

- Location: `carat/use_cases/ex/tab_command_handler.rb:102,`
- Why: carat/use_cases/ex/buffer_command_handler.rb:102, carat/use_cases/ex/history_command_handler.rb:61 duplication (shared logic belongs in the domain, architecture 5): three copies of the same ASCII-digits predicate digits?
- Fix: keep one domain function (for example ExGrammar.digits? beside letter?) and call it from the three handlers
- Also: carat/use_cases/ex/buffer_command_handler.rb, carat/use_cases/ex/history_command_handler.rb
- Category: editor
- Added: 2026-11-19

### Carat/use_cases/ex/buffer_command_handler.rb (sprint-20 sweep quality, tab_command_handler.rb:45,)

- Location: `carat/use_cases/ex/tab_command_handler.rb:45,`
- Why: carat/use_cases/ex/buffer_command_handler.rb:79, carat/use_cases/ex/lsp_start_command_handler.rb:27, carat/use_cases/ex/lsp_restart_command_handler.rb:26, carat/domain/substitute_args.rb:89, carat/domain/register_count.rb:62 duplication: six places build the literal 'E488: Trailing characters: ...', while E16 and invalid_argument live in Domain::Messages
- Fix: add Messages.trailing_characters(text) and call it from all six
- Also: carat/use_cases/ex/buffer_command_handler.rb, carat/use_cases/ex/lsp_start_command_handler.rb, carat/use_cases/ex/lsp_restart_command_handler.rb, carat/domain/substitute_args.rb, carat/domain/register_count.rb
- Category: editor
- Added: 2026-11-19
