# Tasks

## 1. Command, grammar, and registers

- [ ] 1.1 Add `carat/domain/command.rb` (the `Command` value with `count_or`), `carat/domain/registers.rb` (`RegisterEntry`, `Registers` with write, read, and uppercase append), and `carat/domain/command_grammar.rb` (digits, register prefix, operators, counts that multiply, doubling, character arguments, cancel, `typed`); add them to `carat.rb`; verify with `test/domain_grammar.rb` and `test/domain_registers.rb`
- [ ] 1.2 Extend `carat/domain/editor_state.rb` with `registers`, `grammar`, `last_find`, and `showcmd`, add `Find` to `command.rb`, `Window#height` to `window.rb`, and `Buffer#text_of`/`lines_of` helpers to `buffer.rb`; verify with `test/domain_buffer.rb` rows for the helpers and that `make build` passes

## 2. Motions

- [ ] 2.1 Add `carat/domain/motions.rb` with the `Motion` value and the left-right, up-down, line, word, sentence, paragraph, and screen motions; rewrite `carat/use_cases/move.rb` to apply a `Motion` to the cursor with the wanted-column rules; verify with `test/editor_motions.rb` covering every scenario of the motions spec that moves the cursor

## 3. Text objects

- [ ] 3.1 Add `carat/domain/text_objects.rb` with the word, WORD, sentence, paragraph, bracket, and quote objects; verify with `test/editor_text_objects.rb` covering every scenario of the text-objects spec

## 4. Operators and the key path

- [ ] 4.1 Add `carat/domain/operators.rb` (extract, delete, put, join, shift over ranges) and `carat/use_cases/operate.rb` (operand resolution with the exclusive adjustments, register writes, cursor and mode placement, the standalone commands); verify with `test/editor_operators.rb` covering every scenario of the operators spec and the operator rows of the motions spec
- [ ] 4.2 Change `carat/use_cases/handle_key.rb` to run normal and operator-pending keys through the grammar, `carat/use_cases/dispatcher.rb` to take a `Command` and route operators and motions, `carat/adapters/editor_assembly.rb` to wire `Operate`, and `carat/adapters/frame_presenter.rb` to record the window height and paint `showcmd`; verify with `test/editor_grammar.rb` covering every scenario of the command-grammar spec and `test/editor_registers.rb` covering the registers spec
- [ ] 4.3 Rewrite the bindings in `config/default.json` (operators, standalone commands, register select, the motion set in `normal`, the whole `operator_pending` map), run `make gen-config`, and adjust `test/domain_keymap.rb` and `test/editor_normal.rb` (the "Not implemented" scenario moves to `u`); verify with `test/config_sync.rb`, `test/domain_keymap.rb`, and `test/editor_normal.rb`

## 5. Documentation

- [ ] 5.1 Extend `docs/compatibility.md` with one row per motion, text object, operator, standalone command, and register form, naming the test program whose table holds its row, and `docs/actions.md` with every new action name; verify each row against the test tables
- [ ] 5.2 Update `CLAUDE.md` (Status, Layout) and the README for the editor that now exists; verify every listed command runs as written

## 6. Integration

- [ ] 6.1 Run `make snapshots` for the new and changed test programs, review the diff, then `make check` (build, gen-config, test, diagnose); verify everything passes and the binary still edits a file in a terminal

## Workflow follow-up

- Archive the change, then open the pull request and squash-merge it after CI is green.
