# Carat architecture

Carat is a terminal IDE written in Ruby whose editing model is Neovim's: modal editing, the `[count][operator][motion]` grammar, text objects, registers, and `:` ex commands. It is built, tested, and shipped with Spinel, Matz's ahead-of-time Ruby-to-C compiler, at the Ruby 4 language level. No CRuby installation is required at any point. This document fixes the architecture that every OpenSpec change builds on. It describes the target system, not the current state of the code; the roadmap at the end says in what order the pieces land.

## 1. Goals and non-goals

Goals:

- Feel like Neovim to the hands. Normal, insert, visual, replace, operator-pending, and command-line modes behave as a Neovim user expects, for the subset of commands Carat implements.
- Be an IDE, not only an editor: syntax highlighting, diagnostics, go-to-definition, completion, formatting, a file explorer, and a fuzzy finder, with Ruby as the first-class language.
- Spinel does everything. Building, running, and testing all go through Spinel's project tool `spin`. The result is one native binary, and neither developers nor users need CRuby.
- Be plain Ruby. Readable, testable, no native extensions, no metaprogramming tricks.
- Follow Clean Architecture. Business rules at the center, frameworks and devices at the edge, dependencies pointing inward only.
- Every key binding comes from JSON. There are no bindings hard-coded in Ruby.
- Be extensible with plugins. Anything beyond core modal editing is built on one plugin API, and the same API is open to third parties.

Non-goals:

- Vimscript or Lua compatibility. Configuration is JSON.
- Loading Ruby source at run time. A Spinel binary is fixed at compile time, so plugins are either compiled in as packages or run as separate processes (section 9). There is no `require` of a user file.
- Byte-for-byte Neovim parity. Where Neovim behavior is obscure, Carat picks the simple, documented behavior and records it in a spec.
- GUI front ends. The only front end is a terminal.
- Ractor. Spinel documents Thread, Fiber, Mutex, Queue, SizedQueue, and ConditionVariable, and never mentions Ractor. CRuby 4.0 still marks Ractor experimental. Carat uses threads and queues for concurrency and nothing else.

## 2. Runtime and compiler

- Compiler: Spinel. It parses Ruby with Prism, infers types across the whole program, emits C, and calls the system C compiler. Its language level is Ruby 4; its own benchmark baseline is CRuby 4.0.4. The project pins one exact Spinel commit in the Makefile, so every build, locally and in CI, uses the same compiler; bumping it is a deliberate change in its own pull request.
- Project tool: `spin`, which ships with Spinel. It owns the manifest, dependency resolution, multi-file builds, test runs, packaging, and installation. The repository's `Makefile` is only a map: every target calls `spin` or OpenSpec and builds nothing itself. `make help` lists the targets.
- Development loop: `spin build` compiles every `bin/*.rb` into `build/bin/`, `spin run carat -- FILE` builds and runs the editor, `spin test` compiles and runs every `test/*.rb`. All three need only Spinel and a C compiler.
- Tests are Spinel programs too. `spin test` judges each test program by its exit status and by diffing its stdout against a committed `test/<name>.rb.expected` snapshot. Carat commits every snapshot, so `spin test` never falls back to CRuby. The `--regen` option, which refreshes snapshots by running the test under CRuby, is not used; `make snapshots` rebuilds each test program with Spinel and rewrites its snapshot from that output, and the diff is reviewed before committing.
- One codebase, one runtime. Code that Spinel cannot compile is a bug and fails `spin build`.

### 2.1 Spinel rules for all production code

These come from Spinel's limitations document and from the notes gathered while building the earlier Carat prototype. They are enforced by the compiler itself and by the `lint` test program in section 9.

- Standard library only, and only the parts Spinel bundles: `io/console`, `IO.select`, `IO.pipe`, `Process.spawn`, `open3`, `set`, `forwardable`, `stringio`, `strscan`, `time`, `pathname`, `optparse`. No gems, no `spin` dependencies beyond what the roadmap names. No `json` library: Spinel documents no JSON parser and refuses the pure-Ruby `json/pure`, so Carat ships its own small JSON reader and writer (section 5.4). No `minitest`: tests use Carat's own assertion harness (section 9).
- `IO.popen` is refused by the compiler. A child process with live pipes is started with `Process.spawn` and `IO.pipe` pairs; one-shot commands use `Open3.capture2` or `capture3`.
- No `eval`, no `method_missing`, no `send` or `public_send` with a computed name, no `define_method` under a runtime condition, no `instance_variable_get` or `instance_variable_set` with a computed name, no `const_get` with a runtime name.
- No custom `hash` or `eql?` on classes used as hash keys, and no arrays as hash keys. Keys are strings, symbols, integers, or identity.
- String literals are frozen with no opt-out. Mutable strings are created with `+""`, `String.new`, or `dup`. Line arrays hold only strings; cell arrays hold only one type.
- Every instance variable is assigned in `initialize`. Calling through an unassigned instance variable crashes a release build.
- A method does not both take a block and call itself recursively.
- `require_relative` is inlined at compile time; a missing file is a compile error. The dependency graph of `require_relative` calls is therefore the real module graph.
- `STDIN.raw { }` is the only raw-mode form, and the block must contain a single call, because Spinel rewrites a short raw block and skips a long one.
- Signal handlers set a flag only. A `trap` handler runs where Ruby code may run, not inside a blocking call, so the loop polls with a timeout.
- `SIGINT` and `SIGTERM` are trapped before the first thread starts. Once a program has started a thread, an untrapped signal ends the process at once with no `ensure`, which would leave the terminal in raw mode. Raw mode itself turns off `ISIG`, so `Ctrl-C` arrives as byte 3 and is an ordinary key.
- Threads run with true parallelism and no global lock. Shared state is guarded by `Mutex` or passed through `Queue`; nothing else is shared across threads. A program that never starts a thread behaves exactly as single-threaded Spinel, so the editor core never starts one; only service drivers do.
- Only UTF-8 and binary encodings exist.
- Immutable values are `Data` subclasses written as `class Name < Data.define(...)`. Spinel supports `Data` fully: value equality and hashing, frozen instances, `with`, `to_h`, pattern matching, and member type inference. Mutable records, whose state is a set of fields with readers and writers, are `Struct` subclasses written as `class Name < Struct.new(...)`. Spinel supports the subclass form fully: readers and writers, positional and keyword construction, a custom `initialize` that calls `super`, `==`, `to_a`, `members`, `each_pair`, inline RBS on the subclass's methods, and `# @rbs @member: Type` pins on the members, which it lays out as instance variables. The block forms of `Data.define` and `Struct.new` are not used because inline RBS inside them is ignored; `Struct.new` with a string name, `define_method` inside the block, and singleton methods on an instance are refused by the compiler and never used. Behavior classes, the use cases, adapters, drivers, and ports, are plain classes.
- Every method and attribute carries an inline RBS signature in Spinel's comment form (`#: (String) -> Integer` above a `def`, `# @rbs @ivar: Type` blocks for instance variables, trailing `#: Type` on attributes). Spinel applies them before type inference and trusts them without verification, so a signature describes what the program stores, with `untyped` where a value is genuinely mixed. Optional, rest, and keyword-splat parameters receive no seed, so methods take required parameters. The `lint` test enforces presence; `make types` shows what the compiler inferred.

## 3. Clean Architecture layers

```
            +------------------------------------------------------+
            |  Frameworks and drivers                               |
            |  AnsiTerminal  DiskFiles  ProcessRunner  Threads      |
            |  MainLoop  bin/carat  Spinel build                    |
            |   +----------------------------------------------+   |
            |   |  Interface adapters                           |   |
            |   |  InputController  Presenters (Frame, Screen)  |   |
            |   |  JsonConfigGateway  JsonRpcLanguageGateway    |   |
            |   |   +--------------------------------------+   |   |
            |   |   |  Use cases                            |   |   |
            |   |   |  Move  Operate  Insert  ExecuteEx     |   |   |
            |   |   |  Undo  Search  OpenFile  SaveFile     |   |   |
            |   |   |  ManageWindows  Complete  Diagnose    |   |   |
            |   |   |   +------------------------------+   |   |   |
            |   |   |   |  Entities                     |   |   |   |
            |   |   |   |  Buffer  Range  Cursor        |   |   |   |
            |   |   |   |  Selection  Registers  Marks  |   |   |   |
            |   |   |   |  UndoTree  Keymap  Command    |   |   |   |
            |   |   |   |  Options  Motion  TextObject  |   |   |   |
            |   |   |   +------------------------------+   |   |   |
            |   |   +--------------------------------------+   |   |
            |   +----------------------------------------------+   |
            +------------------------------------------------------+
```

The dependency rule: source code dependencies point inward only. Entities know nothing outside themselves. Use cases know entities and the port interfaces they need, never an adapter. Adapters implement ports and translate between the outside world and use case inputs and outputs. Drivers are the only place that names a concrete terminal, file system, process, or thread.

Crossing a boundary uses plain values: integers, strings, symbols, arrays, and small immutable value objects. No layer hands another a live object from a lower layer that it would have to understand.

Module namespaces follow the layers exactly:

| Layer | Namespace | Directory |
| --- | --- | --- |
| Entities | `Carat::Domain` | `carat/domain/` |
| Use cases | `Carat::UseCases` | `carat/use_cases/` |
| Ports | `Carat::Ports` | `carat/ports/` |
| Interface adapters | `Carat::Adapters` | `carat/adapters/` |
| Frameworks and drivers | `Carat::Drivers` | `carat/drivers/` |

The `lint` test program (section 9) enforces that a file in one directory only requires files from its own directory or an inner one.

## 4. Entities

Pure Ruby objects with no I/O. They hold the editor's state and the rules of modal editing.

- `Buffer`: the text of one file as an array of line strings without newlines, plus `path`, `modified`, and `line_ending`, a `Struct` record. All edits go through four primitives: `insert(pos, text)`, `delete(range)`, `replace(range, text)`, and `set_lines(from, to, lines)`. Each primitive records its inverse in the open `Transaction`. An array of lines handles files up to a few hundred thousand lines; a piece table is a contained later change behind the same primitives.
- `Position`: a `(row, col)` pair in code point columns, a `Data` value. Display width is a presenter concern.
- `Range`: two positions plus a kind: `charwise`, `linewise`, or `blockwise`, and an inclusive flag, a `Data` value. Every operator receives a `Range`.
- `Cursor`: the current position plus `want_col`, the column aimed for when moving vertically through shorter lines, as Vim's `curswant`, a `Struct` record.
- `Selection`: anchor and head of a visual selection, resolved to a `Range` by the visual kind.
- `Transaction` and `UndoTree`: a transaction groups the edits of one command with the cursor before and after. The tree keeps branches so `u`, `Ctrl-R`, and `g-` behave like Vim. Insert mode opens one transaction on entry and closes it on `Esc`.
- `Registers`: named `a` to `z` with uppercase append, numbered `0` to `9` with shifting, unnamed, black hole, and the read-only `%`, `:`, and `.`. Each entry stores text and a kind, so a linewise yank pastes as lines.
- `Marks`: per-buffer lowercase, global uppercase, and the automatic `'`, `.`, `^`, `[`, `]`, `<`, `>`, adjusted on line insert and delete.
- `Options`: typed global and buffer-local options with Vim names, a `Struct` record: `number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, `wrap`, `scrolloff`, `timeoutlen`, `clipboard`.
- `Key`: an integer code. Printable code points are themselves, control characters are their byte, special keys (arrows, function keys, Home, End, Delete, Page Up and Down) are codes above the Unicode range, and Alt is a flag bit. `KeyNotation` converts between codes and the Vim spelling used in JSON: `<CR>`, `<Esc>`, `<C-w>`, `<A-x>`, `<leader>`, `<Up>`, `<F5>`.
- `Mode`: `normal`, `insert`, `replace`, `visual`, `visual_line`, `visual_block`, `operator_pending`, `cmdline`.
- `Keymap`: one trie per mode from key sequences to action names, built from JSON (section 7); the keymap and its `KeymapNode` are `Struct` records. An ambiguous prefix such as `g` before `gg` waits for the next key until `timeoutlen`.
- `Command`: the value the parser produces: register, count, operator, motion or text object, and the keys that formed it for the dot register.
- `CommandGrammar`: the state machine over keys that implements

  ```
  [register] [count] operator [count] (motion | text-object)
  [register] [count] action
  ```

  Counts multiply. A doubled operator (`dd`, `yy`, `cc`, `>>`) is linewise over `count` lines. The grammar produces a `Command` and never touches a buffer.
- `Motions` and `TextObjects`: pure functions from `(state, count)` to a `Range`. Left-right (`h l 0 ^ $ f F t T ; ,`), up-down (`j k G gg + - _`), word (`w W b B e E ge gE`), object (`( ) { }`), search (`n N * #`), marks (`'x` and backtick), screen (`H M L`); text objects `iw aw iW aW is as ip ap` and the pair objects for brackets, quotes, and tags. One implementation serves both cursor movement and operator ranges.
- `Operators`: `d c y p P > < = ~ g~ gu gU gq J r x s S C D Y`, each a function from a `Range` to buffer primitives inside one transaction. `c` ends by requesting insert mode so the dot register can replay typed text.
- `ExCommand` and `ExGrammar`: a parsed command line as `range`, `name`, `bang`, `args`. Addresses are `.`, `$`, `%`, a number, a mark, a pattern, or arithmetic on those, joined by `,` or `;`. Names and abbreviations (`w`, `wr`, `write`) resolve through a registry owned by the use case layer.
- `Window`, `Layout`, `TabPage`: a window is a viewport over a buffer with its own cursor, scroll offsets, and local options, a `Struct` record; a layout is a tree of splits; tab pages hold layouts.
- `Frame` and `Cell`: the view model, both `Struct` records. A frame is a grid of cells, each a code point, display width, and highlight group id, plus the cursor position and shape. It is an entity because presenters and tests both reason about it, and it contains no terminal knowledge. Presenters reuse one frame and repaint its cells in place, because allocating a grid per render churned the heap and corrupted buffers under Spinel's garbage collector.
- `EditorState`: everything a use case reads or changes, a `Struct` record holding the buffer, window, cursor, mode, options, command line, message, pending keys, and quit flag.

## 5. Use cases

Each use case is one class with a single `call` taking a request value and returning a response value. Use cases receive their ports through the constructor. They are the only layer that orchestrates entities, and the only layer that talks to ports.

### 5.1 Editing

- `HandleKey`: the central use case. Feeds a key through the current mode's keymap and the grammar; when a `Command` completes, dispatches it. Returns what changed so the presenter can redraw only what is needed.
- `Move`, `Operate`, `EnterInsert`, `InsertText`, `LeaveInsert`, `Replace`: the normal and insert mode operations behind the actions the keymap names.
- `Undo`, `Redo`, `RepeatLast`: walk the undo tree and replay the dot register.
- `StartVisual`, `ExtendVisual`, `OperateOnSelection`.
- `Search`, `SearchNext`, `Substitute`, `GlobalCommand`: pattern work, including the Vim-to-Ruby regular expression translation for the common escapes.

### 5.2 Files and ex commands

- `OpenFile`, `SaveFile`, `SaveAll`, `Quit`, `QuitAll`: through `FilePort`, with the Vim error codes `E37`, `E212`, `E492` as response values.
- `ExecuteEx`: parses a command line with `ExGrammar` and runs the matching handler from the ex registry: files (`e w wq x q qa wa saveas`), buffers and windows (`bn bp bd ls sp vs only close`), editing (`s g v d m t normal sort`), navigation (`marks registers jumps` and a bare line number), options (`set setlocal`).

### 5.3 Windows and services

- `SplitWindow`, `CloseWindow`, `FocusWindow`, `ResizeLayout`, `OpenTab`.
- `RequestCompletion`, `RequestDefinition`, `RequestHover`, `RequestReferences`, `Rename`, `FormatBuffer`, `ApplyDiagnostics`: each talks to `LanguageServicePort`. They are written so that a port that reports no service available produces an empty response and a message, never an error.
- `RegisterPlugin`, `DispatchPluginAction`, `EmitEvent`, `ApplyPluginEdit`: the plugin host use cases of section 9. The finder, the explorer, and git signs are plugins built on them, not separate use cases.

### 5.4 Shared library inside the inner layers

- `Carat::Json`: a recursive-descent JSON reader and a writer, about two hundred lines, no dependencies, used for configuration and for the JSON-RPC gateway. It lives with the entities because both use cases and adapters need it and it has no I/O.

## 6. Ports

Ports are the interfaces use cases depend on. Each is a Ruby class with methods that raise `NotImplementedError`, so Spinel sees one concrete method table per port.

| Port | Methods | Driver | Test double |
| --- | --- | --- | --- |
| `TerminalPort` | `size`, `read_key(timeout)`, `write(bytes)`, `enter`, `leave` | `AnsiTerminal` | `FakeTerminal` with a scripted key queue and captured output |
| `ClockPort` | `now`, `sleep(seconds)` | monotonic clock | manual clock |
| `FilePort` | `read(path)`, `write(path, text)`, `exist?`, `list(dir)`, `stat(path)` | `DiskFiles` | `MemoryFiles` |
| `ConfigPort` | `load` returning the parsed config value | `JsonConfigGateway` | fixed config |
| `LanguageServicePort` | `start(language)`, `notify(method, params)`, `request(method, params)`, `poll` | `JsonRpcLanguageGateway` | scripted responses |
| `ProcessPort` | `spawn(argv)` returning a handle with `write`, `read_nonblock`, `wait` | `ProcessRunner` | fake handle |
| `MessageQueuePort` | `push(message)`, `pop(timeout)` | `Queue` from the runtime | array-backed |

## 7. Configuration and key maps in JSON

All key bindings come from JSON. The shipped defaults and the user's overrides use one schema, and the keymap entities are built only from that data.

- `config/default.json` in the repository is the single source of truth for default bindings and default options. It is complete: every key Carat responds to is listed there, including `h j k l` and `:`.
- The user file is `~/.config/carat/config.json`, with an optional project file `.carat.json` in the working directory. Loading order is default, user, project, each merged over the previous one; a later file can unbind a key by mapping it to `null`.
- A native binary cannot read `config/default.json` from the repository at run time, so `spin run carat-gen-config` generates `carat/domain/default_config.rb` from it as a Ruby hash literal. The generated file is committed, and the `config_sync` test fails when it is out of date. The JSON file is edited; the Ruby file never is.

Schema:

```json
{
  "leader": " ",
  "timeoutlen": 500,
  "options": {
    "number": true,
    "relativenumber": false,
    "tabstop": 2,
    "shiftwidth": 2,
    "expandtab": true,
    "scrolloff": 5
  },
  "keymaps": {
    "normal": {
      "h": "cursor.left",
      "j": "cursor.down",
      "dd": "operator.delete_line",
      "gg": "cursor.buffer_start",
      ":": "mode.cmdline",
      "<leader>w": ":w<CR>",
      "gd": "lsp.definition"
    },
    "insert": {
      "<Esc>": "mode.normal",
      "<CR>": "insert.newline"
    },
    "visual": {},
    "visual_line": {},
    "visual_block": {},
    "operator_pending": {},
    "cmdline": {}
  },
  "languages": {
    "ruby": {
      "lsp": ["ruby-lsp"],
      "formatter": ["rubocop", "-A", "--stdin", "{file}", "--stderr"]
    }
  },
  "plugins": {
    "explorer": { "enabled": true },
    "finder": { "enabled": true, "options": { "ignore": [".git", "build"] } },
    "spell": { "command": ["carat-spell", "--lang", "en"] }
  },
  "theme": "carat-dark"
}
```

Rules of the schema:

- A keymap value is either an action name in `namespace.action` form, listed in `docs/actions.md`, or a key sequence in Vim notation to remap to, such as `:w<CR>`. A value of `null` removes the binding.
- Keys are written in Vim notation: plain characters, `<CR>`, `<Esc>`, `<Tab>`, `<BS>`, `<Space>`, `<Up>`, `<C-x>`, `<A-x>`, `<F1>` to `<F12>`, `<leader>`.
- Unknown keys, unknown action names, and malformed notation are reported with the file name and the JSON path, and the rest of the file still loads.
- Options in JSON use the Vim names and the same types as `:set`.
- A `plugins` entry with `enabled` refers to a compiled plugin by name. An entry with `command` starts a process plugin. `options` is passed to the plugin unchanged. A plugin's own default bindings live in its manifest and are merged below `keymaps`, so the user file always wins.

## 8. Interface adapters and drivers

### 8.1 Input

- `InputController`: owns the key-to-use-case path. It reads keys from `TerminalPort`, runs them through `HandleKey`, and hands the response to the presenter. It is where the `timeoutlen` wait for ambiguous prefixes is implemented, using `ClockPort`.
- `KeyDecoder`: turns terminal bytes into `Key` codes, disambiguating a lone `Esc` from an escape sequence with a short timeout.

### 8.2 Output

- `FramePresenter`: a pure function from editor state to a `Frame`. It draws every window's text with line numbers and sign column, status lines, the tab line, the command line or message area, and overlays: completion menu and diagnostic text. Display width uses an East Asian width table; tabs expand to `tabstop`.
- `ScreenPresenter`: keeps the last frame and emits only changed cells as ANSI bytes, with cursor shape per mode, the alternate screen, and bracketed paste. One `write` per frame.
- `Highlighter` and tokenizers: line-oriented, incremental tokenizers carrying an opaque state across lines so multi-line strings and comments work. Ruby, Markdown, JSON, YAML, and a plain fallback. Tree-sitter is excluded because it needs a native extension.
- `Theme`: maps highlight groups to 256-color or truecolor values.

### 8.3 Gateways

- `JsonConfigGateway`: reads the three JSON files through `FilePort`, merges them, validates against the schema, and returns a plain config value.
- `JsonRpcLanguageGateway`: speaks JSON-RPC over stdio to a language server started through `ProcessPort`. It translates buffer events to `didOpen`, `didChange`, `didSave`, and requests diagnostics, hover, definition, references, rename, completion, and formatting. It returns plain values: diagnostics as `(range, severity, message)`, completions as `(label, kind, insert_text)`. Use cases never see JSON.

### 8.4 Drivers

- `AnsiTerminal`: raw mode through `io/console`, window size, byte reads with `readpartial` so no bytes hide in a stdio buffer that `IO.select` cannot see.
- `DiskFiles`, `MonotonicClock`.
- `ProcessRunner`: starts a language server with `Process.spawn`, its stdin and stdout connected to `IO.pipe` pairs, stderr to a log file. The handle exposes the write end, the read end for `IO.select`, and `Process.wait`. One-shot tools such as a formatter run through `Open3.capture3` with `stdin_data`.
- `MainLoop`: the single editor thread. One iteration: compute the next timeout from pending key waits, service polls, and the redraw deadline; `IO.select` on the terminal and on the message queue's pipe; decode and handle every ready key; drain the message queue; present if anything is dirty. Resize is a flag set by the `WINCH` handler and checked each iteration.
- `ServiceThreads`: one thread per language server process that blocks on the process's stdout, parses JSON-RPC frames, and pushes messages onto the `MessageQueuePort`. This is the only place threads are created, and the queue is the only thing shared with the editor thread. Spinel runs these threads in parallel with no global lock, so the editor thread never blocks on a service, and the queue is the only synchronization point.
- `bin/carat.rb`: argument parsing, construction of every driver, adapter, and use case, injection in one place, and `STDIN.raw { |io| loop.run }` as the single-call raw block.

## 9. Plugins

Everything beyond core modal editing is a plugin: the file explorer, the fuzzy finder, git signs, and later spell checking, snippets, or a test runner. Third parties use the same API. Because a Spinel binary cannot load code at run time, there are two kinds of plugin with one API between them.

### 9.1 The plugin API

The API is a set of plain values and port methods owned by the use case layer. A plugin never touches an entity or a driver directly.

What a plugin can declare, in its manifest:

- `name`, `version`, and the API version it was written against.
- Actions: names in `plugin.<name>.<action>` form that keymaps may bind, each with a short description for `docs/actions.md`.
- Ex commands: names and abbreviations added to the ex registry, routed back to the plugin.
- Default key bindings, in the same JSON shape as `config/default.json`, merged below the user's bindings.
- Event subscriptions: `buffer_open`, `buffer_change`, `buffer_save`, `cursor_move`, `mode_change`, `window_focus`, `idle`, `resize`, `quit`.
- Options it accepts, with types and defaults.

What a plugin can do, through `PluginHostPort`:

- Read a buffer: lines, cursor, selection, marks, path, modified flag.
- Edit a buffer: a list of `(range, text)` replacements applied as one transaction, so the user undoes a plugin edit in one step.
- Move the cursor, set a selection, set a mark.
- Open a scratch buffer in a split or floating window, with its own keymap bound to the plugin's actions. This is how the explorer and the finder draw their lists: they are ordinary buffers with plugin-owned bindings, in the way Neovim's `oil` and `telescope` present text.
- Show a message, set a status line segment, place signs and virtual text, set highlights for a range.
- Ask for input on the command line with a prompt.
- Run an ex command string.
- Start a child process and receive its output, through the same `ProcessPort` as language servers.

Every call is a request value in and a response value out, with no callbacks. Events are delivered as values too. This shape is what lets one API serve both plugin kinds.

### 9.2 Compiled plugins

A compiled plugin is a `spin` package that depends on `carat` and implements one class with `manifest`, `activate(host)`, `deactivate`, `on_event(event)`, `on_action(name, context)`, and `on_command(command)`. It is listed in `spin.toml` under `[dependencies]` and in `config/plugins.json`, from which `bin/carat-gen-config.rb` generates `carat/plugins/registry.rb`: an explicit `require` and an explicit constructor call per plugin, in order. Spinel sees a fixed list; there is no reflection and no computed constant lookup. The built-in plugins live in `carat/plugins/` inside this repository and go through exactly the same registry, so the API is exercised by the project itself from the first plugin change.

Compiled plugins run on the editor thread and are as fast as the editor. They obey the Spinel rules of section 2.1 and the layer rule: a plugin may require only `carat/plugin_api.rb` and its own files, never the editor's entities, use cases, or drivers. The `lint` test checks this.

### 9.3 Process plugins

A process plugin is any executable started with `command` from the user's config. It speaks the Carat plugin protocol over stdio: JSON-RPC framed as in the Language Server Protocol, with the same message shapes as the API above, specified in `docs/plugin-protocol.md`. On start the plugin sends its manifest; the host registers it as it would a compiled plugin. Requests from the host carry an id and expect a response; events are notifications. The host does not wait on a plugin: a slow response leaves the editor responsive, and a plugin that exits is unregistered with a message.

Process plugins may be written in any language, CRuby included, so an author can prototype in CRuby with the full standard library and gems, then port to a compiled plugin for speed. The `JsonRpcLanguageGateway` and `ServiceThreads` already carry the framing, the process handle, and the queue; the plugin gateway reuses them with a different message table.

### 9.4 Rules

- The editor must start, edit, save, and quit with every plugin disabled. Core editing never depends on a plugin.
- A plugin failure is reported in the message area and disables that plugin; it never ends the editor or corrupts a buffer, because every edit goes through one validated transaction.
- A plugin's bindings never override a user's bindings, and `config/default.json` never contains a plugin's bindings; those belong to the plugin manifest.
- The API is versioned. The host refuses a manifest written against a newer major version and says so.

## 10. Testing strategy

Everything runs through `spin test`, compiled with Spinel. There is no CRuby test runner.

- `carat/testing.rb` is Carat's assertion harness: `Carat::Testing` with `assert_equal`, `assert_true`, `assert_raises`, a table runner that takes rows of input and expected output, and a reporter that prints one deterministic line per test followed by a summary, and exits non-zero on any failure. It is about one hundred lines, uses no reflection, and is the only test dependency. Its output is what the committed `.expected` snapshots contain, so a new failure shows up as a diff with the failing table row in it.
- `test/domain_*.rb` and `test/use_cases_*.rb`: unit test programs for entities and use cases. Motions, operators, and text objects are table-driven: buffer text, cursor, keys, expected text, expected cursor. These tables are the compatibility record in `docs/compatibility.md`.
- `test/adapters_*.rb`: presenter tests compare a `Frame` to an expected grid of strings; `ScreenPresenter` tests check ANSI bytes for a known frame diff; gateway tests feed scripted JSON-RPC frames and assert the plain values produced.
- `test/editor_*.rb`: whole-editor tests with `FakeTerminal`, `MemoryFiles`, a manual clock, and a fixed config: feed keys, assert the frame and the buffer. This is the main integration level.
- `test/lint.rb`: a test program that reads every source file and checks the Spinel rules of section 2.1 that the compiler does not catch on its own, the layer rule of section 3, and the plugin rule of section 9: a file under one layer directory requires only files from its own layer or an inner one, no `eval` or computed `send`, no `IO.popen`, no key binding literals outside `config/default.json`. It prints the violations, so the snapshot is the empty report.
- `test/config_sync.rb`: parses `config/default.json` with `Carat::Json` and compares it to the generated `Carat::Domain::DEFAULT_CONFIG`, so a stale generated file fails the suite.
- `test/smoke_*.rb`: start `build/bin/carat` inside a pseudo-terminal through `Process.spawn`, send keys, and check the file written and the final screen. Few and slow.
- `make diagnose` runs `spinel-doctor`, Spinel's bundled checker, on every compile root: unsupported constructs, unresolved calls, slots widened to `untyped`, boxing advice for hot loops, and a build. Its behavior leg, which compares against a CRuby interpreter, is skipped because the project uses none and Ruby 4 output differs from Ruby 3. It is part of `make check` and must report clean. Its advice lines are the guide for where a signature is worth tightening.
- Continuous integration installs Spinel from source and runs `spin build` and `spin test` on Ubuntu.

## 11. Repository layout

The layout is the one `spin` expects: a manifest, a library file with a directory of the same name, `bin/` compile roots, and `test/` programs.

```
spin.toml                       manifest: package name, version, no dependencies
Makefile                        command map over spin and OpenSpec; builds nothing itself
.gitignore                      build/ and dist/
bin/carat.rb                    entry point and composition root; builds to build/bin/carat
bin/carat-gen-config.rb         generates carat/domain/default_config.rb from config/default.json
config/default.json             every default option and key binding
carat.rb                        require graph, outermost layer first
carat/version.rb
carat/testing.rb                assertion harness used by test/*.rb
carat/domain/                   entities
  buffer.rb position.rb range.rb cursor.rb selection.rb transaction.rb
  undo_tree.rb registers.rb marks.rb options.rb key.rb key_notation.rb
  mode.rb keymap.rb command.rb command_grammar.rb motions.rb text_objects.rb
  operators.rb ex_command.rb ex_grammar.rb window.rb layout.rb tab_page.rb
  frame.rb cell.rb json.rb default_config.rb (generated)
carat/use_cases/
  handle_key.rb move.rb operate.rb enter_insert.rb insert_text.rb
  leave_insert.rb undo.rb redo.rb repeat_last.rb visual/*.rb search/*.rb
  files/*.rb execute_ex.rb ex/*.rb windows/*.rb language/*.rb finder/*.rb
carat/ports/
  terminal_port.rb clock_port.rb file_port.rb config_port.rb
  language_service_port.rb process_port.rb message_queue_port.rb
carat/adapters/
  input_controller.rb key_decoder.rb frame_presenter.rb screen_presenter.rb
  highlighter.rb tokenizers/*.rb theme.rb json_config_gateway.rb
  json_rpc_language_gateway.rb
carat/drivers/
  ansi_terminal.rb disk_files.rb process_runner.rb monotonic_clock.rb
  main_loop.rb service_threads.rb
carat/plugin_api.rb             the only file a plugin may require
carat/plugins/
  registry.rb (generated)       explicit require and constructor per plugin
  explorer/ finder/ git_signs/  built-in compiled plugins
carat/adapters/json_rpc_plugin_gateway.rb
config/plugins.json             the ordered list of compiled plugins
carat/doubles/
  fake_terminal.rb memory_files.rb manual_clock.rb fake_process.rb
test/                           one program per file, each with a committed .expected
  domain_buffer.rb domain_motions.rb ... use_cases_*.rb adapters_*.rb
  editor_*.rb lint.rb config_sync.rb smoke_*.rb
build/                          spin output, ignored by git
docs/
  architecture.md compatibility.md actions.md plugin-protocol.md
openspec/                       specs are the behavioral source of truth
```

## 12. Roadmap as OpenSpec changes

Each item is one OpenSpec change and one pull request, in this order. Each leaves the editor usable, and `spin build` and `spin test` green.

1. `project-skeleton`: `spin.toml`, the `carat.rb` require graph, `Carat::Testing`, the `Json` entity with its tests, `config/default.json` with the generator executable and the `config_sync` test, the `lint` test, continuous integration that builds Spinel and runs `spin build` and `spin test`, and a `bin/carat.rb` that opens a file and quits. This change proves the whole toolchain before any editing exists.
2. `editor-foundation`: ports and drivers, `Buffer` with the four primitives, `KeyDecoder`, `Keymap` from JSON, `HandleKey`, `FramePresenter` and `ScreenPresenter` for one window, normal and insert modes with the foundation bindings, command-line mode with `:w :q :wq :e`, and the editor test harness.
3. `command-grammar`: `CommandGrammar`, counts, registers, the full motion set, the first operators, text objects. `docs/compatibility.md` starts here.
4. `undo-and-registers`: `Transaction`, `UndoTree`, `u`, `Ctrl-R`, the dot command, numbered and named registers.
5. `visual-modes`: charwise, linewise, and blockwise selection with operators.
6. `search-and-substitute`: `/ ? n N * #`, `hlsearch`, `incsearch`, `:s`, `:g`, `:v`.
7. `buffers-windows-tabs`: buffer list, splits, `Ctrl-W` commands, tab pages, and their ex commands.
8. `syntax-highlighting`: tokenizer interface, Ruby tokenizer, themes, color output.
9. `options-and-config`: `:set`, local options, user and project config files with merge and unbinding.
10. `language-services`: `ProcessPort`, `ServiceThreads`, `JsonRpcLanguageGateway`, `ruby-lsp` integration, diagnostics, go-to-definition, hover, completion menu.
11. `plugin-host`: `carat/plugin_api.rb`, the manifest, the plugin host use cases, the generated registry from `config/plugins.json`, events, scratch buffers with plugin-owned keymaps, and the lint rule for plugin dependencies. Proven by a tiny built-in `hello` plugin that adds one action and one ex command.
12. `plugin-explorer-and-finder`: the file tree and the fuzzy finder as the first real compiled plugins.
13. `plugin-protocol`: `docs/plugin-protocol.md`, the JSON-RPC plugin gateway reusing the language service framing, and a sample process plugin written in CRuby to prove the protocol from outside the binary.
14. `plugin-git-and-formatting`: git signs and status as a plugin; RuboCop formatting through the language service.
15. `release-build`: reproducible builds for Linux and macOS with `spin build` and `spin pack`, release packaging, `spin install`, and the smoke tests against the released binary.

Before item 10 starts, a short spike verifies on Spinel that a subprocess with piped stdin and stdout can be read from a thread while the main thread sits in `IO.select`. The spike result is recorded in the change's design document.

## 13. Decisions and alternatives

| Decision | Chosen | Alternatives considered | Why |
| --- | --- | --- | --- |
| Toolchain | Spinel and `spin` for everything: build, run, test, package | CRuby for development with Spinel for releases; CRuby only | One runtime means no behavior drift between tests and the shipped binary, and no CRuby install anywhere |
| Test harness | Own `Carat::Testing` with snapshot output under `spin test` | `minitest`; `test-unit` | Neither framework compiles with Spinel; snapshot diffs make failures readable and the harness is tiny |
| Lint | A Spinel-compiled `test/lint.rb` | RuboCop | RuboCop needs CRuby; the rules Carat needs are few and specific |
| Architecture | Clean Architecture with four layers and the dependency rule | Layered MVC; hexagonal only | Entities and use cases are testable with no terminal; drivers and compilers can change at the edge |
| Key bindings | JSON, defaults included, generated into Ruby for the binary | Ruby config file; bindings in code | One schema for defaults and users; no metaprogramming; data is diffable and validatable |
| JSON | Own two-hundred-line reader and writer | stdlib `json`; a gem | Spinel bundles no JSON library and refuses the pure one; the subset Carat needs is small |
| Concurrency | One editor thread, one thread per service, a queue between | Ractor; async with fibers; everything on one thread | Spinel documents threads and queues, not Ractor; fibers have no scheduler on Spinel; one thread would block on slow servers |
| Child processes | `Process.spawn` with `IO.pipe`, `Open3` for one-shot tools | `IO.popen` | `IO.popen` is refused by Spinel at compile time |
| Text storage | Array of line strings behind four primitives | Rope; piece table | Simplest structure for the target sizes; replaceable later |
| Command handling | Grammar produces a value, use case executes | Handlers mutate state while parsing | Pure parsing makes the dot register, macros, and tests simple |
| Rendering | Full frame then diff | Incremental region updates | Simple to reason about and already minimal in bytes |
| Highlighting | Hand-written line tokenizers | Tree-sitter | No native extension; Spinel cannot link it |
| IDE features | Use cases over `LanguageServicePort` | Built into the editor loop | Optional, replaceable, and mockable |
| Plugins | Two kinds, compiled packages and processes, over one value-based API | Runtime Ruby loading; Lua; processes only | A Spinel binary cannot load code; compiled plugins give speed, process plugins give any-language freedom, and one API keeps both honest |
