# Design

## Context

See proposal.md for motivation. The skeleton gives us `Carat::Json`, `Carat::Testing`, the generated `DEFAULT_CONFIG_JSON`, the lint test with the layer rule, and a `bin/carat.rb` that only prints. `docs/architecture.md` fixes the layers, module names, ports, and the Spinel rules; this design fills in how the foundation pieces fit inside those constraints.

Spinel facts that shape the code, verified with a probe program against the pinned compiler:

- Inline RBS can pin `Array[T]`, `Hash[String, T]`, `Hash[Symbol, T]`, program classes, and nullable forms; it cannot pin `Hash[Integer, T]`, so a hash keyed by key codes would stay unannotated. The keymap trie is therefore keyed by the key code's decimal string.
- `Integer#chr("UTF-8")` is refused; code points become strings with `[cp].pack("U")`.
- `io.raw { }` is desugared into save and restore of the terminal mode when the block holds at most 60 statements and no `def`; the block in `bin/carat.rb` holds one call.
- `IO.select`, `readpartial`, `STDOUT.winsize` (with `require "io/console"`), `Process.clock_gettime(Process::CLOCK_MONOTONIC)`, `Signal.trap` with a block that only sets a flag, and `PTY.spawn` (with `require "pty"`) all compile and run.
- `spin test` compiles and runs `test/*.rb` only; `bin/*.rb` are built by `spin build`.
- A return type annotated on a method that a subclass overrides is reported as not applied (the overriding calls share one return representation) and only the parameter types apply. Port methods and their driver and double overrides therefore carry `# @rbs name: Type` parameter lines, or `# @rbs skip` when they take no parameters, with the return described in prose; a `void` return is annotated normally because it pins nothing.

## Goals / Non-Goals

**Goals:**

- One key path: terminal bytes, decoder, keymap, `HandleKey`, use case, state, presenter, terminal bytes, with every piece replaceable by a double.
- Every piece of state the later roadmap items need to attach to already has a home: the buffer primitives for transactions, `Cursor#want_col` for motions, `Range` with a kind for operators, `EditorState#pending_keys` for the grammar, `Frame` highlight ids for themes.
- Deterministic whole-editor tests that read like Vim sessions.

**Non-Goals:**

- Any behavior of a later roadmap item, even when it would be cheap. The grammar, counts, registers, undo, visual mode, search, splits, highlighting, options as `:set`, user config files, services, and plugins are not started here.
- Performance work. An array of strings and a full frame per redraw are the documented choices.

## Decisions

### Entities

- `Position(row, col)` and `Range(from, to, kind, inclusive)` are small immutable values; `Range` is `Carat::Domain::Range`, nested as the architecture names it. Spinel compiles a nested class named after a builtin, and inside `Carat::Domain` the bare name resolves to ours; code in other layers that needs Ruby's range uses literals only. Only the charwise exclusive kind is exercised in this change; linewise and blockwise are carried as values for the operators change.
- `Buffer` keeps `lines`, `path` (nullable), `modified`, and `line_ending`. Its four primitives are the only mutators and each ends by setting `modified`. `Buffer.from_text(text, path)` and `#to_text` do the line-ending work. A later transaction hooks into the primitives without changing their signatures.
- `Cursor(row, col, want_col)` with `want_col` -1 meaning "line end" (Vim's `$`), set by horizontal motions and read by vertical ones.
- `Window` is a viewport: `top` and `left` scroll offsets plus `scroll_into_view(cursor, height, width, scrolloff)`. One window exists; the layout tree arrives with windows and tabs.
- `Mode` is a module of symbols with `Mode.from_name(String)` for the JSON names.
- `Options` is a typed value built from the config `options` object with the Vim names used here: `number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scrolloff`; the remaining names load but are unused.
- `Key` is a module of integer constants: special keys from 0x110000 upward, `ALT` as bit 0x400000. `KeyNotation.parse(text, leader)` returns a `KeyNotation::Result` with `codes` and `error` (nullable string), and `KeyNotation.format(code)`.
- `Keymap` holds one `KeymapNode` trie per mode name. `lookup(mode, codes)` returns a `KeymapMatch` with `kind` in `:none`, `:prefix`, `:match`, `:match_prefix` and `value` (the action name or remap sequence). `Keymap.build(keymaps_hash, leader)` fills `errors` with "mode.key: reason" strings and keeps going.
- `ExCommand(name, bang, args)` and `ExGrammar.parse(text)`. A range field is not added yet; `ExCommand` gains it with the editing commands.
- `Frame`, `Cell(char, width, hl)`: `Frame.new(rows, cols)` filled with blank cells, `put(row, col, text, hl)` honoring display width, `row_text(row)` for tests, `cursor_row`, `cursor_col`, `cursor_shape`. Highlight ids are integers with named constants in `Highlight`: `NORMAL`, `LINE_NUMBER`, `STATUS`, `MESSAGE_ERROR`, `NON_TEXT`.
- `EditorState` aggregates `buffer`, `window`, `cursor`, `mode`, `options`, `timeoutlen`, `cmdline`, `message`, `message_error`, `pending_keys`, and `quit`. It is the value every use case receives; use cases mutate it and return a small response.

### Use cases

- `HandleKey#call(state, code)` appends the key to `state.pending_keys`, asks the keymap, and acts on the match: `:match` dispatches and clears, `:prefix` and `:match_prefix` return `:pending`, `:none` clears and, in insert or cmdline mode, inserts the printable keys that were pending. `HandleKey#timeout(state)` resolves a `:match_prefix` by dispatching the shorter binding. A new key clears the previous message before anything else.
- Dispatch is a `case` over the action string in `Dispatcher`, which calls the use case objects it was constructed with; unknown names show "Not implemented: name". A value that does not match `name.name` is a remap sequence and is replayed through `HandleKey` with a depth counter capped at 100.
- `Move`, `EnterInsert`, `InsertText`, `LeaveInsert`, `EditCommandLine`, `OpenFile`, `SaveFile`, `Quit`, `ExecuteEx`, and `ShowMessage` each expose one `call`. `ExecuteEx` holds the registry as a `case` over the command name with the long forms as additional arms; E492 otherwise.
- `OpenFile` and `SaveFile` take `FilePort` in the constructor and return a message string; errors from the port are rescued there and become Vim's E212 message.

### Ports, adapters, drivers, doubles

- `TerminalPort#read_key(timeout)` returns the raw bytes of one read, or `nil` on timeout; the decoder is an adapter so the port stays byte-level. `size` returns `[rows, cols]`; `write`, `enter`, and `leave` complete it.
- `KeyDecoder#feed(bytes)` returns the key codes decoded so far and keeps an incomplete escape or UTF-8 sequence pending; `#pending?` and `#flush` (a lone Escape) serve the timeout. `KeyDecoder.encode(code)` is the inverse used by `FakeTerminal#type`, so tests write keys in Vim notation.
- `InputController#pump(state)` does one read with a timeout chosen from the decoder (50 ms while an escape is pending), the keymap (`timeoutlen` while a match is pending), or the idle poll (250 ms, so resize and `SIGTERM` flags are seen), then feeds every decoded key through `HandleKey` and returns whether anything changed.
- `FramePresenter#call(state, rows, cols)` is pure; it scrolls the window first so the state and the frame agree, then paints gutter, text, tilde rows, status line, and message row.
- `ScreenPresenter#present(frame)` keeps the previous frame and emits one write: full repaint when the size changed or it is the first frame, otherwise only rows with a changed cell, then the cursor position and shape. `enter` and `leave` write the alternate-screen sequences through the terminal port.
- `AnsiTerminal` is the only user of `io/console`, `IO.select`, and `readpartial`. `DiskFiles` wraps `File` and `Dir`. `MonotonicClock` wraps `Process.clock_gettime`. `JsonConfigGateway#load` parses `DEFAULT_CONFIG_JSON`; merging user files is the config change.
- `MainLoop#run(state)` loops until `state.quit` or the `SIGTERM` flag: pump, then present when dirty or resized. `bin/carat.rb` traps `INT`, `TERM`, and `WINCH` before anything else, builds the graph, and runs `STDIN.raw { |io| loop.run(state) }` inside `begin ... ensure screen.leave end`.
- `Carat::Doubles::EditorHarness` builds the same graph with `FakeTerminal`, `MemoryFiles`, `ManualClock`, and `FixedConfig`, and offers `type(notation)`, `tick(ms)`, `frame`, `screen_rows`, `buffer`, `cursor`, `mode`, `message`, and `files`. It pumps the controller exactly as `MainLoop` does, so editor tests exercise the controller and presenters, not a shortcut.

### Tests

- `test/domain_buffer.rb`, `test/domain_keys.rb`, `test/domain_keymap.rb`, `test/domain_ex_grammar.rb`, `test/adapters_key_decoder.rb`, `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/use_cases_ex.rb`, `test/editor_normal.rb`, `test/editor_insert.rb`, `test/editor_cmdline.rb`, `test/editor_screen.rb`, `test/smoke_editor.rb`, each with a committed snapshot produced by `make snapshots`.
- The smoke test uses `PTY.spawn` on `build/bin/carat`, waits for the alternate-screen sequence, types keys, waits for the process, and checks the file and the trailing output. It prints only pass and fail lines so the snapshot is stable.

## Risks / Trade-offs

- [A terminal left in raw mode after a crash] → the raw block's `ensure` restores the mode and `bin/carat.rb` leaves the alternate screen in its own `ensure`; `SIGINT` and `SIGTERM` are trapped before the loop starts so no untrapped signal can skip them.
- [Timing-dependent smoke test on a slow CI runner] → the test reads until it sees expected output before typing and waits on the child with `Process.waitpid2`, with no fixed sleeps except the decoder's own escape timeout, which the test crosses by sending Escape in its own write.
- [The `Range` name shadowing Ruby's] → only literal ranges are used inside `Carat::Domain`; the lint rule already forbids computed constant lookup, and the compiler qualifies the nested class.
- [Keymap values for unimplemented actions in the default config] → they dispatch to a visible "Not implemented" message, so the config stays complete and the gap is obvious rather than silent.
- [Display width for wide characters is a small table] → documented in the proposal; the highlighting change revisits the presenter and brings the full table.
