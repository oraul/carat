## 1. Jump motions

- [x] 1.1 `Motions::JUMP_NAMES`, `Motions.jump?`, `Window#record_jump` (`carat/domain/motions.rb`, `carat/domain/window.rb`); `Move`, `Operate#operand`, `JumpToMatch`, and `ExecuteEx#go_to` record (`carat/use_cases/move.rb`, `operate.rb`, `search/jump_to_match.rb`, `ex/execute_ex.rb`); proved by `test/editor_jumps.rb` ("Each jump form records the position left", "Ctrl-I comes back after a jump", "A failed jump records nothing", "Other motions record nothing", "A jump under an operator records the position left")

## 2. The % motion

- [x] 2.1 `motion.match_pair` in `Motions` with its bindings in the five modes (`carat/domain/motions.rb`, `config/default.caratrc`, `make gen-config`); proved by `test/editor_motions.rb` ("Percent goes to the matching bracket", "Percent goes back from a closing bracket", "Percent without a bracket does nothing", "A count goes to that percent of the buffer", "Percent under an operator is inclusive")

## 3. The alternate buffer

- [x] 3.1 `Window#alternate`, copied by `copy_from` and `OpenTab`; `BufferList#load` sets it and `alternate_of` reads it (`carat/domain/window.rb`, `carat/domain/buffer_list.rb`, `carat/use_cases/windows/open_tab.rb`); proved by `test/editor_jumps.rb` ("A split keeps the alternate buffer")
- [x] 3.2 `buffer.alternate` through `BufferHandler` and `SwitchBuffer` target `:alternate`, bound to `<C-^>`; `<C-6>` and `<C-^>` in `KeyNotation` (`carat/use_cases/actions/buffer_handler.rb`, `carat/use_cases/buffers/switch_buffer.rb`, `carat/domain/key_notation.rb`, `config/default.caratrc`); proved by `test/editor_jumps.rb` ("Ctrl-^ goes back and forth", "Ctrl-6 is Ctrl-^", "A count goes to that buffer", "No alternate buffer", "A modified buffer refuses Ctrl-^") and `test/domain_keys.rb`
- [x] 3.3 `:e #` in `FileCommandHandler#edit`, which takes the buffer list (`carat/use_cases/ex/file_command_handler.rb`, `carat/adapters/editor_assembly.rb`); proved by `test/editor_jumps.rb` (":e # shows the alternate file", ":e # without an alternate file")

## 4. Docs

- [x] 4.1 `docs/compatibility.md` (`%`, `<C-^>`, `:e #` rows, the `<C-o>` row, Differences), `docs/actions.md`, `README.md`'s jump sentence, `docs/architecture.md`'s `Window` entry, `docs/codebase-map.md` area 11's tests
- [x] 4.2 `make gates`, `make spec-validate`, `make docs-lint`, and the targeted tests pass
