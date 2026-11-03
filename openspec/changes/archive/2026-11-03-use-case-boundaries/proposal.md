# Proposal

## Why

A use case is meant to be one operation with one entry point, but the use cases under `carat/use_cases/` have grown into bags of operations: on 6299df8, 29 files there exposed 175 public methods besides `call` (`Undo` had `undo redo to travel line list`, `Operate` had `fixed replace_chars toggle_case put join`, `InsertText` had `newline backspace delete tab`, `EditCommandLine` had `start append backspace cancel execute`, `OperateOnSelection` had eleven verbs, `FileOps` nine), 31 constants were defined in use cases, and `Operate::CHANGE`, `DELETE`, `YANK`, `INDENT`, `DEDENT`, and `Quit::E37` were read from other files. The user set the rule "a use case with a call and the rest in private": a use case exposes only `call`, everything else is private, and its constants are `private_constant`. The user agreed five points on how to get there, which this change follows.

## What Changes

- Every use case of the core (everything under `carat/use_cases/` except the handlers, the two tables, the `CommandRunner` interface, `Outcome`, the concerns, and the plugin host under `use_cases/plugins/`) exposes exactly one public instance method, `call`, besides `initialize` and the readers the shared-instance test needs; everything else is private.
- Point 1, split by operation: each real operation with its own inputs becomes its own use case, a verb phrase with one public `call` and a keyword constructor. `Undo` becomes `UndoStep`, `RedoStep`, `UndoToState`, `TravelHistory`, `RestoreLine`, `ListUndo`, and `WalkHistory`; `Operate` keeps the operators and gives `r`, `~`, `p`/`P`, and `J` to `ReplaceChars`, `ToggleCase`, `PutRegister`, and `JoinLines`; the insert keys become `BreakLine`, `EraseCharacter`, and `InsertTab` beside `InsertText`; the command line becomes `EnterCommandLine`, `EditCommandLine`, `EraseCommandLine`, `CancelCommandLine`, and `ExecuteCommandLine`; `OperateOnSelection` becomes eight selection use cases; `FileOps` becomes `ProbePath`, `MakePath`, `RenamePath`, and `DeletePath`; and `SaveAll`, `QuitAll`, `CloseOtherWindows`, `CloseOtherTabs`, `OpenSideWindow`, `ReselectVisual`, and `SwapVisualEnds` are split off their former hosts. design.md lists every split and the count.
- Point 2, variants through one call: `FocusWindow` takes a `FocusRequest` (`target`, `count`) and `SwitchTab` a `TabRequest`; a variant that is only a name or a flag (`Quit`'s way, a selection's shape, a direction) is a plain argument of `call`. `HandleKey`'s `timeout` becomes the key `Domain::Key::TIMEOUT` through `call`, and its `pending?` is read from the input state.
- Point 3, merges: `InsertModeHandler` absorbs `EnterInsert` and `WindowHandler` absorbs `ResizeLayout`, since each handler only forwarded to a stateless use case nothing else called; `NormalModeHandler` leaves a visual mode itself.
- Point 4, shared logic: what several operations share and needs no port moves to the domain (`UndoTree#undo_path` and `#redo_path`, `SelectionCut`, `Selection#lines_or_block` and `#numbered_delete?`, `Block#reaching_rows`, `BufferList#close_window` and `#close_tab`, `EditorState#clamp_col`, `Options#tab_width`, `Messages`, `OperatorKind`); what needs a port stays a use case the others call (`WalkHistory` reads the clock, `ProbePath` the file port, `SaveFile` writes for `SaveAll`).
- Point 5, the plugin side: the request families and `PluginLink` are the adapter of `PluginApi::Host` and keep their request methods by design; the registry, entries, events, router, and tokenizer part are host infrastructure, not use cases, and move out of `use_cases` with the host in a later plugin-side change, recorded in `docs/backlog.md`. This change only adapts their calls to the split core use cases.
- Constants read outside their use case move to the domain: the operator names to `Domain::OperatorKind`, `E37`, `E36`, the read-only register and empty register messages, and the "seconds ago" text to `Domain::Messages`, and `PluginSyntax::FAILED` to `Domain::SyntaxLine::FAILED`. Every other constant under `carat/use_cases/` is listed in a `private_constant`.
- `test/lint.rb` gains three rules, each with a self-check: a use case class has exactly one public instance method, `call` (handlers, tables, `CommandRunner`, `Outcome`, records, concerns, and `use_cases/plugins/` excepted); every constant under `carat/use_cases/` is in a `private_constant`, since the pinned Spinel compiles `private_constant` without enforcing it; and no file names `X::CONST` of a use case `X` outside the use case's own file.
- `CLAUDE.md` (Layout, Coding conventions) and `docs/architecture.md` section 5 describe the one-call rule, the splits, and the plugin-side decision.

No editor behavior changes: every key, ex command, message, and screen stays the same, and every test keeps its meaning.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a refactor of the use case layer; `skip_specs` is set for this change.

## Impact

- `carat/use_cases/**/*.rb`: the splits, the private methods and constants, the handlers binding to the new classes.
- `carat/domain/`: `messages.rb`, `operator_kind.rb`, `selection_cut.rb` (new); `undo_tree.rb`, `selection.rb`, `block.rb`, `buffer_list.rb`, `editor_state.rb`, `options.rb`, `key.rb`, `syntax_line.rb` (helpers).
- `carat/adapters/editor_assembly.rb` (the wiring and its readers), `carat/adapters/input_controller.rb` (the timeout key and the input state).
- `test/lint.rb` (the three rules), `test/adapters_assembly.rb` (the holders of the new classes), `test/use_cases_ex.rb` and `test/use_cases_plugins.rb` (the wiring they build by hand).
- `CLAUDE.md`, `docs/architecture.md`, `docs/backlog.md`.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a code-quality refactor the user asked for, with the five points the user agreed.

Out of scope: moving the plugin host out of `carat/use_cases/` and giving the core a port for it (the later plugin-side change); any change to the handlers' and tables' public shape beyond their collaborators; renaming the use cases that already had only `call`; any behavior change.

Assumptions recorded here instead of asked: a variant that is a single name or flag is a plain argument rather than a one-field `Data` value, which keeps the hot paths free of an allocation per key; `OLDEST` and `NEWEST` become private constants of `WalkHistory`, which answers them for an empty path, so `UndoStep`, `RedoStep`, and `TravelHistory` hand it an empty path at the end of the history; `Move` stays a use case beside `MotionHandler`, because two handler instances of two kinds share it and its last find; and `HighlightView`, `HandleKey`, `Dispatcher`, `ArrangeView`, `LeaveInsert`, `RepeatLast`, `OpenFile`, `OpenTab`, `SplitWindow`, and `ExecuteEx` already had one public `call` and change only where a collaborator moved.
