# Design

## Context

The rule the user set: a use case exposes only `call`; everything else is private, and its constants are `private_constant`. The five points the user agreed:

1. Split by operation, not by method: each real operation with its own inputs becomes its own use case class, a verb phrase with one public `call` and a keyword constructor.
2. Variants of one operation take a small request value through the one `call` instead of a class per variant.
3. Merge a handler with its use case when the handler only forwards, since the handler is already an input port with `call`.
4. Logic shared by several operations moves into domain services; logic that needs a port stays a use case of its own that the others call.
5. The plugin request families are the adapter of `PluginApi::Host` and keep their request methods; decide whether the registry, entries, and events move out of `use_cases` as host infrastructure, and record it.

Measured on 6299df8 with a line scanner over `carat/use_cases/`: 29 files exposed 175 public instance methods besides `call`, 31 constants were defined there, and six were read from other files (`Operate::DELETE`, `CHANGE`, `YANK`, `INDENT`, `DEDENT` by the operator and edit handlers, `Quit::E37` by the file command handler), plus `PluginSyntax::FAILED` by `HighlightView`.

A probe on the pinned Spinel: `private` is enforced (a call to a private method raises `NoMethodError`), `private_constant` compiles but is not enforced (the constant stays readable from outside). The lint test therefore carries the constant rules.

## Goals / Non-Goals

Goals: one public `call` per core use case, private helpers and constants, shared logic in the domain, the lint rules that keep it so, no behavior change, the analysis at 2 re-narrowing rounds, the benchmark within 10 percent on `lh`, `j`, `insert`, `dd`, and `undo`, and the allocation budget passing.

Non-goals: restructuring the plugin host (point 5's move is the later plugin-side change); changing handlers or tables beyond their collaborators.

## Decisions

### The splits (point 1)

| Before | After |
| --- | --- |
| `Undo` (`undo redo to travel line list`) | `UndoStep` (u), `RedoStep` (Ctrl-R, `:redo`), `UndoToState` (`:undo N`), `TravelHistory` (g-, g+, `:earlier`, `:later`), `RestoreLine` (U), `ListUndo` (`:undolist`), and `WalkHistory`, the shared replay, cursor rule, and message |
| `Operate` (`fixed replace_chars toggle_case put join`) | `Operate` (the operators; the handler builds the fixed command of `x s S C D Y` itself), `ReplaceChars` (r), `ToggleCase` (~), `PutRegister` (p, P), `JoinLines` (J) |
| `InsertText` (`newline backspace delete tab`) | `InsertText` (typed text), `BreakLine` (Enter), `EraseCharacter` (Backspace and Delete), `InsertTab` (Tab) |
| `EditCommandLine` (`start append backspace cancel execute`) | `EnterCommandLine` (:), `EditCommandLine` (typed text), `EraseCommandLine` (Backspace), `CancelCommandLine` (Esc), `ExecuteCommandLine` (Enter) |
| `OperateOnSelection` (eleven verbs) | `DeleteSelection` (d x Del X D), `YankSelection` (y Y), `ChangeSelection` (c s S R C), `ShiftSelection` (> <), `JoinSelection` (J gJ), `RecaseSelection` (~ u U r), `InsertAtSelection` (I A), `PutOverSelection` (p P) |
| `StartVisual` (`toggle leave reselect`) | `StartVisual` (v V Ctrl-V), `ReselectVisual` (gv); leaving is `NormalModeHandler`'s |
| `ExtendVisual` (`swap_ends swap_corner text_object`) | `ExtendVisual` (the text objects), `SwapVisualEnds` (o O) |
| `SaveFile` (`write all`) | `SaveFile` (one buffer to a path), `SaveAll` (`:wa`, `:wqa`, `:xa`) |
| `Quit` (`leave all`) | `Quit` (`:q`, `:q!`, and after a write), `QuitAll` (`:qa`) |
| `FileOps` (`cwd probe list same_path? make rename delete follow_rename mark_deleted`) | `ProbePath`, `MakePath`, `RenamePath`, `DeletePath`; the plugin requests read `cwd` and `list` from the file port |
| `CloseWindow` (`close only remove remove_in`) | `CloseWindow` (`:close`, Ctrl-W c), `CloseOtherWindows` (`:only`, Ctrl-W o); removing a window is `BufferList#close_window` |
| `CloseTab` (`close only`) | `CloseTab`, `CloseOtherTabs`; removing a tab page is `BufferList#close_tab` |
| `SplitWindow` (`side`) | `SplitWindow`, `OpenSideWindow` |
| `FocusWindow` (`direction cycle previous`) | `FocusWindow` with a `FocusRequest` |
| `SwitchTab` (`next previous first last`) | `SwitchTab` with a `TabRequest` |
| `ResizeLayout` (`equalize`), `EnterInsert` (`indent_of`), `Move` (`first_nonblank`), `HandleKey` (`pending? timeout`) | merged into `WindowHandler` and `InsertModeHandler`; `Move` keeps `call`; `HandleKey` keeps `call` |

The count: 37 new use case classes and 2 request values; `Undo`, `OperateOnSelection`, `FileOps`, `EnterInsert`, and `ResizeLayout` are gone. The new domain files are `Messages`, `OperatorKind`, and `SelectionCut`.

### Variants (point 2)

A variant that carries a count with its target is a `Data` request: `FocusRequest(target:, count:)` for `FocusWindow` (left, down, up, right, next, previous, last accessed) and `TabRequest(target:, count:)` for `SwitchTab` (next, previous, first, last). A variant that is one name or one flag is a plain argument of `call`: `Quit#call(state, way)` with `:quit`, `:force`, or `:written`; `DeleteSelection` and `ChangeSelection` with a shape (`:selected`, `:lines`, `:to_end`); `EraseCharacter` forward or not; `ShiftSelection` a direction. A one-field `Data` value would add an allocation per key on paths the benchmark measures and say nothing a symbol does not.

`HandleKey` had `timeout(state)` beside `call(state, code)`; both run the same key machinery, so the timeout becomes a key value, `Domain::Key::TIMEOUT`, above the special keys and never bound, that `call` resolves as the old `timeout` did. `pending?` was a forward to the input state, which the input controller now receives itself.

### Merges (point 3)

A handler absorbs its use case when it only forwarded to a use case that holds no shared state and that nothing else calls: `InsertModeHandler` takes `EnterInsert`'s six entry positions (its `first_nonblank` and `indent_of` are the buffer's), and `WindowHandler` takes `ResizeLayout`'s one line. `Move` stays: the motion and find handlers are two instances of two kinds that share it and its last find, which the shared-instance test checks. `TabHandler` forwards to `SwitchTab`, which the tab ex commands share, so it stays too.

### Shared logic (point 4)

- `UndoTree#undo_path(count)` and `#redo_path(count)`: the steps `u` and Ctrl-R take, in the path format `path_to` returns, so `UndoStep` and `RedoStep` hand a path to `WalkHistory`.
- `WalkHistory#call(state, path, undoing, absolute)`: the replay, Neovim's cursor rule, the modified flag, and the message, the one place that reads the clock; an empty path answers `Already at oldest change` when undoing and `Already at newest change` otherwise, or nothing for `:undo N` (`absolute`), so `OLDEST` and `NEWEST` are private to it.
- `Domain::SelectionCut.call(state, selection)`: deleting a selection and placing the cursor, shared by delete, change, and put over a selection; `Selection#lines_or_block(to_end)` and `#numbered_delete?` (the register 1 rule); `Block#reaching_rows`.
- `BufferList#close_window(index, id)` and `#close_tab(index)`: removing a window or a tab page and releasing the buffers, shared by `CloseWindow`, `CloseOtherTabs`, `CloseTab`, `Quit`, and the plugin host.
- `EditorState#clamp_col(row, col)` and `Options#tab_width`, which most of the split classes repeated privately.
- `Domain::Messages`: `E36`, `E37`, `read_only_register`, `nothing_in_register`, and `seconds_ago`, each used by more than one use case or handler; `Domain::OperatorKind`: the five operator names.
- What needs a port stays a use case: `WalkHistory` and `ListUndo` (clock), `ProbePath` (the file port, called by the other path use cases and the file requests), `SaveFile` (called by `SaveAll`).

### The plugin side (point 5)

Decision: the request families (`BufferRequests`, `WindowRequests`, `FileRequests`, `UiRequests`) and `PluginLink` are the adapter of `PluginApi::Host`, one method per request by design, and keep their request methods. The registry, entries, events, router, and tokenizer part are not use cases but host infrastructure, and they move out of `carat/use_cases/` with the whole host: the plugin-side change moves `use_cases/plugins/` (with `Guarded` and `Boundary`) to `carat/adapters/plugins/`, the adapter between compiled plugins and the core, and gives the core a port for the calls it makes into the host (observe, saved, resized, answer, action, command, tokenize), since a use case may not name an adapter. That change is too large to carry here: it reworks the host's construction, the assembly, and five test programs. Until it lands, the one-call rule skips `carat/use_cases/plugins/`; the constant rules cover it. `docs/backlog.md` records it.

### The lint rules

- One call: in a file under `carat/use_cases/`, a plain class (not a `Data` or `Struct` record, not a subclass of `ActionHandler` or `ExHandler`) outside `concerns/` and `plugins/`, other than `ActionTable`, `ExTable`, `CommandRunner`, `Outcome`, `ActionHandler`, and `ExHandler`, has no public `def` but `initialize` and `call`, and no `attr_writer` or `attr_accessor`; `attr_reader` stays allowed for the shared-instance test.
- Private constants: every constant assigned in a file under `carat/use_cases/` is named in a `private_constant` line of that file.
- Constant reads: no file of the library, the executables, the tests, or the benchmark names `X::CONST` for a constant `CONST` of a use case class `X` outside the file that defines it.

## Risks / Trade-offs

- More classes and longer handler constructors: the handlers now take each operation they bind; the assembly builds each once.
- `WalkHistory` takes an array path for `u` and Ctrl-R, one small allocation per undo key that the old loop did not make; the undo scenario's time is checked.
- The plugin host keeps its many-method classes until the plugin-side change.

## Migration Plan

None: no behavior, configuration, or plugin API change.
