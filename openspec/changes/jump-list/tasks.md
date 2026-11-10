## 1. The jump list per window

- [x] 1.1 `JumpList#step` checks the bounds before it records the start (`carat/domain/jump_list.rb`); proved by `test/domain_jump_list.rb` ("Ctrl-O on an empty list leaves it empty")
- [x] 1.2 `Window` gains the `jumps` member, copied by `copy_from` (`carat/domain/window.rb`, `carat.rb` order); `OpenTab` copies it into the new tab page's window (`carat/use_cases/windows/open_tab.rb`); proved by `test/editor_jumps.rb` ("A split copies the jump list", "A new tab page copies the jump list", "A window walks only its own list")
- [x] 1.3 `VisitTarget` and `WalkJumps` read the current window's list; `EditorAssembly` drops the shared list (`carat/use_cases/definitions/visit_target.rb`, `walk_jumps.rb`, `carat/adapters/editor_assembly.rb`); proved by `test/adapters_definitions.rb` and `test/adapters_assembly.rb`

## 2. Buffer switches record

- [x] 2.1 `BufferList#enter` records the position left and loads (`carat/domain/buffer_list.rb`); `OpenFile`, `SwitchBuffer`, and `VisitTarget#view` call it; proved by `test/editor_jumps.rb` ("Every buffer switch records the position left", "Ctrl-O walks back through several switches", "A file opened over the startup buffer records nothing", "Deleting a buffer records nothing")
- [x] 2.2 `:bf[irst]`, `:br[ewind]`, `:bl[ast]` (`carat/use_cases/buffers/buffer_request.rb`, `switch_buffer.rb`, `carat/domain/buffer_list.rb`, `carat/use_cases/ex/buffer_command_handler.rb`); proved by `test/editor_buffers.rb` ("First and last", "Rewind is first", "First refused on a modified buffer")

## 3. The tab rule

- [x] 3.1 `Options#jump_takes_tab?` replaces the two copies of the option test; `hand_tab` returns for a scratch target (`carat/domain/options.rb`, `carat/domain/buffer_list.rb`, the two use cases); proved by `test/editor_jumps.rb` ("A walk back to a scratch buffer keeps the file's tab") and `test/adapters_definitions.rb` ("Ctrl-O across a buffer switch gives the tab back")

## 4. Docs and records

- [x] 4.1 `docs/compatibility.md` rows (`<C-o>`, `<C-i>`, `option.jumptab`, `:bfirst`, `:blast`), `README.md`'s jump sentence, `docs/architecture.md`'s Options list with prose trimmed, `docs/codebase-map.md` lines and the new test
- [x] 4.2 `docs/backlog.md`: the four fixed entries removed and the owners moved (the planner's new entries are the package step's)
- [ ] 4.3 `make gates`, `make spec-validate`, `make docs-lint`, and the targeted tests pass
