# Proposal

## Why

Carat has a toolchain, a JSON reader, a test harness, and a configuration mirror, but no editor: `bin/carat` prints a line count and exits. Roadmap item 2 of `docs/architecture.md`, `editor-foundation`, turns the skeleton into a usable modal editor so that every later item (the command grammar, undo, visual mode, search, windows, highlighting, services, plugins) has a buffer, a key path, a renderer, and a whole-editor test harness to build on.

## What Changes

This change delivers roadmap item 2, `editor-foundation`.

- Add the ports the editor core needs now, `TerminalPort`, `ClockPort`, `FilePort`, and `ConfigPort`, with their drivers `AnsiTerminal`, `MonotonicClock`, `DiskFiles`, and the `JsonConfigGateway` adapter, and their test doubles `FakeTerminal`, `ManualClock`, `MemoryFiles`, and `FixedConfig`.
- Add the `Buffer` entity with its four primitives `insert`, `delete`, `replace`, and `set_lines`, the `Position`, `Range`, and `Cursor` values, `Window` as a viewport, `Mode`, `Options`, `ExCommand` with `ExGrammar`, `Frame` and `Cell`, and `EditorState` holding them.
- Add `Key` codes and `KeyNotation`, the `KeyDecoder` that turns terminal bytes into key codes, and `Keymap`, one trie per mode built only from the JSON configuration, with `timeoutlen` waiting on ambiguous prefixes and key-sequence remaps.
- Add `HandleKey` and the use cases behind the foundation bindings in `config/default.json`: cursor motions, mode switches, insert-mode editing, the command line, and `OpenFile`, `SaveFile`, `Quit`, and `ExecuteEx` with `:w`, `:q`, `:wq`, `:e`, their bang forms, and their long forms `:write`, `:quit`, `:edit`.
- Add `FramePresenter` and `ScreenPresenter` for one window: line numbers, a status line, a message and command line row, cursor shape per mode, the alternate screen, and minimal redraws.
- Add `InputController` and `MainLoop`, and make `bin/carat.rb` the composition root that runs the editor in raw mode on a terminal.
- Add the editor test harness, `Carat::Doubles::EditorHarness`, and the whole-editor tests `test/editor_*.rb` that feed keys through `FakeTerminal` and assert the frame, the buffer, and the files; plus `test/smoke_editor.rb`, which runs `build/bin/carat` in a pseudo-terminal.
- Add `docs/compatibility.md` and `docs/actions.md`, and update `CLAUDE.md` (Status, Commands, Layout) and the README.

Out of scope, delivered by later roadmap items: counts, operators, registers, the dot command, undo and redo, visual modes, search, word motions, splits and tabs, syntax highlighting and themes, user and project configuration files, language services, and plugins. Bindings for those actions stay in `config/default.json`; pressing one shows a "Not implemented" message until its roadmap item lands.

Assumptions recorded here rather than asked:

- The lone-escape timeout of the key decoder is fixed at 50 milliseconds; `ttimeoutlen` as an option arrives with the options change.
- `:q` with unsaved changes reports E37 exactly as Vim does; `<C-c>` in normal mode shows Carat's variant of Vim's hint, naming `:q!` because there is one window and no `:qa` yet.
- The smoke test uses Spinel's bundled `pty` package (`require "pty"`) from the test program only, since `Process.spawn` alone cannot allocate a pseudo-terminal. It is test-only and adds no manifest dependency.
- The smoke test needs `build/bin/carat`, which `spin test` does not build, so `make test` gains `build` as a prerequisite; `make check` and CI already build first.
- The `insert.tab` action inserts spaces to the next multiple of `tabstop` when `expandtab` is set and a tab character otherwise, and `insert.newline` copies the current line's leading whitespace when `autoindent` is set.
- Display width is 1 per code point except for a small table of wide ranges (CJK, Hangul, fullwidth forms, emoji); a complete East Asian width table is left for the highlighting change, where the presenter is revisited.

## Capabilities

### New Capabilities

- `text-buffer`: the editor's text store: lines, the four edit primitives, the modified flag, line-ending detection, and round-tripping file text.
- `key-input`: decoding terminal bytes into key codes (printable characters, control keys, escape sequences for special keys, Alt) and the Vim key notation used in configuration.
- `keymap-config`: key bindings loaded only from JSON, one map per mode, prefix waiting bounded by `timeoutlen`, key-sequence remaps, and reporting of malformed bindings.
- `normal-mode`: cursor movement, the desired column when moving vertically, switching to insert mode at the positions Vim uses, and the quit hint.
- `insert-mode`: inserting typed text, newline, backspace, delete, tab, arrow keys, and returning to normal mode.
- `command-line-mode`: entering and editing the command line, and the ex commands `:w`, `:q`, `:wq`, and `:e` with their bang and long forms and Vim's messages.
- `screen-rendering`: the one-window frame layout (line numbers, text, status line, message row), scrolling with `scrolloff`, tab expansion, cursor shape per mode, the alternate screen, and minimal terminal output.
- `editor-startup`: running `carat FILE` on a terminal: opening an existing or new file, requiring a terminal, restoring it on exit, and ending on `SIGTERM`.

### Modified Capabilities

None; no main spec exists yet.

## Impact

- New directories `carat/ports/`, `carat/use_cases/`, `carat/adapters/`, `carat/drivers/`, and `carat/doubles/`, new entities under `carat/domain/`, and the require graph in `carat.rb`.
- `bin/carat.rb` becomes the real entry point; its skeleton output is replaced by the editor.
- `config/default.json` is unchanged in its bindings; the generated mirror is regenerated only if the JSON changes.
- `Makefile`: `test` depends on `build` so the smoke test finds the binary.
- Tests: `test/domain_*.rb`, `test/use_cases_*.rb`, `test/adapters_*.rb`, `test/editor_*.rb`, and `test/smoke_editor.rb` with their snapshots; `test/lint.rb` is unchanged and now covers five layers.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `CLAUDE.md`, `README.md`.
- No new dependencies: standard library only, with `io/console` and `pty` from what Spinel bundles.
