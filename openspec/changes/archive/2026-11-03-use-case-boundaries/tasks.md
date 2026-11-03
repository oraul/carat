# Tasks

## 1. Domain services and values

- [x] 1.1 Add `Domain::Messages` (`E36`, `E37`, `read_only_register`, `nothing_in_register`, `seconds_ago`) and `Domain::OperatorKind` (the five operator names) in `carat/domain/`; proved by `test/editor_operators.rb`, `test/editor_registers.rb`, `test/editor_undo.rb`, and `test/editor_cmdline.rb`, whose messages stay the same
- [x] 1.2 Add `UndoTree#undo_path` and `#redo_path` in `carat/domain/undo_tree.rb`; proved by `test/editor_undo.rb`
- [x] 1.3 Add `Domain::SelectionCut`, `Selection#lines_or_block` and `#numbered_delete?`, and `Block#reaching_rows` in `carat/domain/`; proved by `test/editor_visual.rb` and `test/domain_selection.rb`
- [x] 1.4 Add `BufferList#close_window` and `#close_tab`, `EditorState#clamp_col`, `Options#tab_width`, `Key::TIMEOUT`, and `SyntaxLine::FAILED` in `carat/domain/`; proved by `test/editor_windows.rb`, `test/editor_tabs.rb`, `test/editor_grammar.rb`, and `test/editor_syntax.rb`

## 2. Split the use cases

- [x] 2.1 Split `Undo` into `UndoStep`, `RedoStep`, `UndoToState`, `TravelHistory`, `RestoreLine`, `ListUndo`, and `WalkHistory` under `carat/use_cases/history/`, bound by `HistoryHandler` and `HistoryCommandHandler`; proved by `test/editor_undo.rb`
- [x] 2.2 Split `Operate` into `Operate`, `ReplaceChars`, `ToggleCase`, `PutRegister`, and `JoinLines`, bound by `EditHandler` and `OperatorHandler`; proved by `test/editor_operators.rb`, `test/editor_registers.rb`, and `test/editor_repeat.rb`
- [x] 2.3 Split `InsertText` into `InsertText`, `BreakLine`, `EraseCharacter`, and `InsertTab`, and merge `EnterInsert` into `InsertModeHandler`; proved by `test/editor_insert.rb` and `test/editor_repeat.rb`
- [x] 2.4 Split `EditCommandLine` into `EnterCommandLine`, `EditCommandLine`, `EraseCommandLine`, `CancelCommandLine`, and `ExecuteCommandLine`; proved by `test/editor_cmdline.rb` and `test/editor_plugins.rb`
- [x] 2.5 Split `OperateOnSelection` into the eight selection use cases, `StartVisual` into `StartVisual` and `ReselectVisual`, and `ExtendVisual` into `ExtendVisual` and `SwapVisualEnds`, bound by `SelectionHandler`, `OperatorHandler`, `VisualModeHandler`, and `NormalModeHandler`; proved by `test/editor_visual.rb`
- [x] 2.6 Split `SaveFile` into `SaveFile` and `SaveAll`, `Quit` into `Quit` and `QuitAll`, and `FileOps` into `ProbePath`, `MakePath`, `RenamePath`, and `DeletePath`, adapting the plugin host's file and UI requests; proved by `test/editor_cmdline.rb`, `test/use_cases_ex.rb`, and `test/use_cases_plugin_files.rb`
- [x] 2.7 Split `CloseWindow`, `CloseTab`, and `SplitWindow`, give `FocusWindow` a `FocusRequest` and `SwitchTab` a `TabRequest`, and merge `ResizeLayout` into `WindowHandler`, adapting the plugin registry and window requests; proved by `test/editor_windows.rb`, `test/editor_tabs.rb`, and `test/editor_explorer.rb`
- [x] 2.8 Resolve the key timeout through `HandleKey#call` with `Key::TIMEOUT` and give `InputController` the input state; proved by `test/editor_grammar.rb` and `test/drivers_main_loop.rb`
- [x] 2.9 Make every remaining helper of a use case private and list every constant under `carat/use_cases/` in a `private_constant`; proved by `test/lint.rb`

## 3. Wiring, rules, and documents

- [x] 3.1 Wire the new classes in `carat/adapters/editor_assembly.rb` with a reader each, and update the holders in `test/adapters_assembly.rb` and the hand-built wiring in `test/use_cases_ex.rb` and `test/use_cases_plugins.rb`; proved by those tests
- [x] 3.2 Add the one-call, private-constant, and constant-read rules with their self-checks to `test/lint.rb`; proved by `test/lint.rb`
- [x] 3.3 Describe the rule, the splits, and the plugin-side decision in `CLAUDE.md`, `docs/architecture.md` section 5, and `docs/backlog.md`
- [x] 3.4 Run `make check`, `make bench` against 6299df8, and `make bench-budget`, and record the numbers in the pull request
