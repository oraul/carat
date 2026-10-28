# Carat architecture

Carat is a terminal IDE written in Ruby whose editing model is Neovim's: modal editing, the `[count][operator][motion]` grammar, text objects, registers, and `:` ex commands. This document fixes the architecture that every OpenSpec change builds on. It describes the target system, not the current state of the code; the roadmap at the end says in what order the pieces land.

## 1. Goals and non-goals

Goals:

- Feel like Neovim to the hands. Normal, insert, visual, replace, operator-pending, and command-line modes behave as a Neovim user expects, for the subset of commands Carat implements.
- Be an IDE, not only an editor: syntax highlighting, diagnostics, go-to-definition, completion, formatting, a file explorer, and a fuzzy finder, with Ruby as the first-class language.
- Be plain Ruby. Readable, testable, no native extensions in the core, no metaprogramming tricks.
- Stay compilable. The core is written in the restricted Ruby subset that the Spinel ahead-of-time compiler accepts, so a single native binary remains a build target.

Non-goals:

- Vimscript or Lua compatibility. Configuration is Ruby.
- A plugin marketplace. Extensions are Ruby files loaded from the config directory.
- Byte-for-byte Neovim parity. Where Neovim behavior is obscure, Carat picks the simple, documented behavior and records it in a spec.
- GUI front ends. The only front end is a terminal.

## 2. Runtime decision

Carat runs on CRuby 3.3 or newer during development and testing, and that is the supported runtime for the first releases. The core is kept Spinel-compatible so a native build can be added as a later change without a rewrite.

What that means in practice for the core (everything under `lib/carat/core`):

- No gems. Only the standard library, and only the parts Spinel provides: `io/console` for raw mode and window size, `IO.select`, byte-level reads.
- No `eval`, `method_missing`, `define_method`, `send` with a computed name, or `instance_variable_get`.
- No custom `hash` or `eql?`, and no arrays as hash keys.
- String literals are treated as frozen everywhere. Mutable strings are created with `+""`, `String.new`, or `dup`.
- Arrays of lines hold only strings. Arrays of cells hold only one type.
- Every instance variable is initialized in `initialize`.
- A method does not both take a block and call itself recursively.
- Only UTF-8 and binary encodings are used.

The host layer (`lib/carat/host`) runs on CRuby only and may use threads, subprocesses, `JSON`, and gems. It is where language servers, formatters, and the config loader live. The core never requires anything from the host; the host plugs into the core through the ports in section 4.

Assumption recorded here: the request said "made with Ruby" and did not name Spinel. The earlier Carat prototype was built with Spinel, so the design keeps that path open at low cost rather than committing to it or closing it. If native compilation becomes a hard requirement, section 9 lists what moves.

## 3. Layered view

```
+--------------------------------------------------------------+
|  bin/carat            entry point, argument parsing            |
+--------------------------------------------------------------+
|  host                 CRuby-only services                      |
|    config loader      LSP client       formatter   git         |
|    process runner     file watcher     fuzzy finder            |
+--------------------------------------------------------------+
|  core                 Spinel-compatible, no gems               |
|    app                Editor, event loop, options, messages    |
|    input              key decoding, modes, keymap, parser      |
|    commands           motions, operators, text objects, ex     |
|    model              Buffer, Cursor, Selection, Undo, Regs    |
|    view               Window, layout, Renderer, Frame, Screen  |
|    syntax             tokenizers, highlight groups, theme      |
|    ports              Terminal, Clock, FileSystem, Service     |
+--------------------------------------------------------------+
|  adapters             AnsiTerminal, FakeTerminal, RealClock    |
+--------------------------------------------------------------+
```

Dependencies point downward only. `model` knows nothing about `view`. `commands` mutate `model` and read `view` state such as the window height for `Ctrl-D`. `app` owns everything and runs the loop. `host` depends on `core`; `core` never depends on `host`.

## 4. Ports and adapters

The core talks to the outside world only through small interfaces. Each has a real adapter and a fake used in tests.

| Port | Methods | Real adapter | Test adapter |
| --- | --- | --- | --- |
| `Terminal` | `size`, `read_key(timeout)`, `write(bytes)`, `enter`, `leave` | `AnsiTerminal` over raw-mode stdin and stdout | `FakeTerminal` with a scripted key queue and captured frames |
| `Clock` | `now`, `sleep(seconds)` | monotonic clock | manual clock advanced by tests |
| `FileSystem` | `read(path)`, `write(path, text)`, `exist?`, `list(dir)`, `stat(path)` | `File` and `Dir` | in-memory hash |
| `Service` | `start`, `request(method, params)`, `notify(method, params)`, `poll` | JSON-RPC over a subprocess, host only | scripted responses |

`Service` is the seam for everything IDE-like. The core exposes hooks such as "buffer changed", "cursor moved", "request completion at position", and the host wires language servers to them. When no service is attached, those features are simply absent and the editor still works. This is what lets the core compile without the host.

## 5. The core, module by module

### 5.1 model

- `Buffer`: the text of one file as an array of line strings without newlines, plus `path`, `modified`, `encoding`, and `line_ending`. All edits go through four primitives: `insert(pos, text)`, `delete(range)`, `replace(range, text)`, and `set_lines(from, to, lines)`. Each primitive records an inverse operation in the active `Transaction`. An array of lines is the right structure for files up to a few hundred thousand lines, which covers the target use. A piece table is a contained later change behind the same four primitives if ever needed.
- `Position`: a `(row, col)` pair in character columns, with `byte_col` computed on demand for rendering. Columns count Unicode code points; display width is a view concern.
- `Range`: two positions plus a kind: `charwise`, `linewise`, or `blockwise`, matching Vim's three motion types. Every operator receives a `Range`.
- `Cursor`: the current position plus `want_col`, the column the user is "aiming for" when moving vertically through shorter lines, exactly as Vim's `curswant`.
- `Selection`: the active visual selection as an anchor and a head, resolved to a `Range` by the visual mode kind.
- `Transaction` and `UndoTree`: a transaction groups the primitive edits of one command and stores their inverses together with the cursor before and after. The undo tree keeps branches so `u`, `Ctrl-R`, and `g-` behave like Vim. Insert mode opens one transaction on entry and closes it on `Esc`.
- `Registers`: named (`a` to `z`, uppercase appends), numbered (`0` to `9` with shifting), unnamed, black hole, and the read-only `%`, `:`, `.` registers. Each entry stores text and a kind, so a linewise yank pastes as lines.
- `Marks`: per-buffer lowercase marks and global uppercase marks, plus the automatic ones Carat implements: `'`, `.`, `^`, `[`, `]`, `<`, `>`. Marks are adjusted on insert and delete of lines.
- `Search`: the last pattern, direction, and offset; pattern matching uses Ruby regular expressions with the Vim-to-Ruby translation limited to the common escapes.

### 5.2 input

- `KeyDecoder`: turns the byte stream from the terminal into `Key` values. A `Key` is an integer code: printable code points as themselves, control characters as their byte, and special keys (arrows, function keys, Home, End, Delete, Page Up and Down) as codes above the Unicode range. Modifier state for Alt is a flag bit. Escape sequence disambiguation uses a short timeout from `Clock`, so a lone `Esc` and the start of a sequence are told apart.
- `Mode`: an enumeration: `normal`, `insert`, `replace`, `visual`, `visual_line`, `visual_block`, `operator_pending`, `cmdline`, and `terminal` reserved for later. The editor is always in exactly one mode. Each mode has a keymap and a `pending` state.
- `Keymap`: a trie from key sequences to `Action` names, one trie per mode. User mappings from the config are inserted into the same tries, so `nnoremap`-style remapping is ordinary data. Ambiguous prefixes (for example `g` versus `gg`) wait for the next key with a timeout, matching Vim's `timeoutlen`.
- `CommandParser`: implements the Vim grammar as a small state machine over keys in normal and visual modes:

  ```
  [register] [count] operator [count] (motion | text-object)
  [register] [count] command
  ```

  The parser accumulates `"a`, counts, an operator such as `d`, `c`, `y`, `>`, `<`, `=`, `g~`, `gu`, `gU`, and then a motion or text object. The two counts multiply. A doubled operator (`dd`, `yy`, `cc`, `>>`) applies linewise to `count` lines. The parser produces a `Command` value: register, count, operator, motion or text object, and the keys that formed it for the `.` register. It never touches the buffer; that is the dispatcher's job.

### 5.3 commands

- `Motions`: every motion is a pure function from `(editor, count)` to a `Range` with a kind and an inclusive or exclusive flag. Grouped as: left-right (`h`, `l`, `0`, `^`, `$`, `f`, `F`, `t`, `T`, `;`, `,`), up-down (`j`, `k`, `G`, `gg`, `+`, `-`, `_`), word (`w`, `W`, `b`, `B`, `e`, `E`, `ge`, `gE`), object (`(`, `)`, `{`, `}`), search (`/`, `?`, `n`, `N`, `*`, `#`), marks (`'x`, `` `x ``), and screen (`H`, `M`, `L`). Because motions are pure, the same function serves cursor movement and operator ranges.
- `TextObjects`: `iw`, `aw`, `iW`, `aW`, `is`, `as`, `ip`, `ap`, and the pair objects for `()`, `[]`, `{}`, `<>`, quotes, and tags. Each returns a `Range` like a motion.
- `Operators`: `d`, `c`, `y`, `p`, `P`, `>`, `<`, `=`, `~`, `g~`, `gu`, `gU`, `gq`, `J`, `r`, `x`, `s`, `S`, `C`, `D`, `Y`, and the register-aware variants. An operator takes a `Range` and runs inside one `Transaction`. `c` ends by switching to insert mode so the dot register can replay the typed text.
- `Dispatcher`: executes a `Command` from the parser: resolves the range, picks the operator, opens the transaction, applies it, records the command for `.`, and updates marks and registers. Non-operator commands (`i`, `a`, `o`, `v`, `:`, `u`, `Ctrl-R`, `zz`, window commands) are plain actions keyed by name.
- `Ex`: the command-line language. `ExParser` splits a line into `range`, `name`, `bang`, and `args`, where a range is any of `.`, `$`, `%`, a number, a mark, a pattern, or arithmetic on those, with `,` or `;` between two addresses. `ExRegistry` maps names and their abbreviations (`w`, `wr`, `write`) to handlers. The first set covers file commands (`e`, `w`, `wq`, `x`, `q`, `qa`, `wa`, `saveas`), buffers and windows (`bn`, `bp`, `bd`, `ls`, `sp`, `vs`, `only`, `close`), editing (`s`, `g`, `v`, `d`, `m`, `t`, `normal`, `sort`), navigation (`line number`, `marks`, `registers`, `jumps`), and options (`set`, `setlocal`, `map` family). The same registry serves `:help`-style listing.

### 5.4 view

- `Window`: a viewport over a buffer with its own cursor, scroll offsets, and local options (`number`, `relativenumber`, `wrap`, `cursorline`, `scrolloff`). Several windows may show the same buffer.
- `Layout`: a tree of horizontal and vertical splits whose leaves are windows, plus a list of tab pages. It resizes on terminal resize and answers "which window is left of this one" for `Ctrl-W h`.
- `Renderer`: a pure function from editor state to a `Frame`: a grid of `Cell` values, each a code point, a display width, and a highlight group id. It draws, in order, every window's text with line numbers and sign column, the window status lines, the tab line, the command line or message area, and overlays such as the completion menu and floating diagnostics. Display width uses an East Asian width table so wide characters occupy two cells and tabs expand to `tabstop`.
- `Screen`: keeps the last frame and emits only the changed cells as ANSI sequences, moving the cursor and switching colors as little as possible. Output is one `write` per frame. It also owns the alternate screen, cursor shape per mode, and bracketed paste.
- `Theme`: maps highlight group names (`Normal`, `Comment`, `Keyword`, `String`, `LineNr`, `StatusLine`, `Visual`, `Search`, `DiagnosticError`) to colors. Colors are 256-color or truecolor depending on the terminal.

### 5.5 syntax

- `Tokenizer`: an interface returning `(start, end, group)` spans for a line, with an opaque state carried from the previous line so multi-line strings and comments work. Tokenizers are hand-written, line-oriented, and incremental: a change to line `n` re-tokenizes from `n` until the carried state matches the previous run.
- First tokenizers: Ruby, Markdown, JSON, YAML, and a plain fallback. Tree-sitter is not used in the core because it needs a native extension; a host service may provide richer highlighting later through the same span interface.

### 5.6 app

- `Editor`: the single root object. It holds the buffer list, the layout, the registers, marks, options, the current mode and parser state, the message line, and the jump list. All state lives here or below it, never in globals, so the whole editor is constructible in a test.
- `Options`: typed global and local options with the Vim names used by the implemented features: `number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, `wrap`, `scrolloff`, `timeoutlen`, `clipboard`. `:set` reads and writes them.
- `Loop`: the event loop. One iteration: compute the next timeout from pending key timeouts, pending service polls, and a redraw deadline; `IO.select` on the terminal and on any host service pipes; decode and handle every ready key; let the host deliver service messages; render if anything is dirty. The loop is single-threaded. Resize is detected by a flag set in the `WINCH` handler and checked each iteration, so a redraw never waits for a keypress.
- `Messages`: the message line and the `:messages` history, including the Vim error codes Carat reuses, such as `E37`, `E212`, and `E492`.

## 6. The key path, end to end

```
bytes  --KeyDecoder-->  Key
Key    --Mode keymap-->  mapped keys  --CommandParser-->  Command
Command --Dispatcher-->  Range (via Motion or TextObject)
Range  --Operator-->  Buffer primitives inside one Transaction
Transaction --> UndoTree, Registers, Marks, dot register
dirty  --Renderer-->  Frame  --Screen diff-->  ANSI bytes  --Terminal-->  tty
```

Every arrow is a plain method call on a plain object. Nothing on this path depends on CRuby-only features.

## 7. Host services

The host layer runs the parts of an IDE that need the outside world. Each service is started lazily on first use and is optional.

- `Lsp::Client`: speaks JSON-RPC to a language server subprocess over stdio. Ruby uses `ruby-lsp`. The client translates buffer events into `didOpen`, `didChange`, `didSave`, and asks for diagnostics, hover, definition, references, rename, completion, and formatting. Results come back to the core as plain values: diagnostics as `(range, severity, message)`, completions as `(label, kind, insert_text)`. The core draws them; it never sees JSON.
- `Formatter`: runs RuboCop in autocorrect mode or an LSP formatting request on `:format` or on save when `formatonsave` is set.
- `Finder`: a fuzzy finder over file names, buffer lines, and symbols, with a scoring function in Ruby and the file list from a background `Dir` walk that respects `.gitignore`.
- `Explorer`: a file tree in a side window, rendered as an ordinary buffer with its own keymap, in the way `netrw` and `oil` present directories as text.
- `Git`: status for the sign column and the status line, from `git` subprocess calls.
- `Watcher`: polls file modification times so a buffer changed on disk prompts a reload.

Services share one `ProcessRunner` that owns subprocesses and exposes their pipes to the loop's `IO.select`.

## 8. Configuration

Configuration is a Ruby file at `~/.config/carat/init.rb`, loaded by the host with `load` after the editor is constructed. It receives a `Carat::Config` object with a small, explicit API:

```ruby
config.set :number, true
config.set :tabstop, 2
config.map :normal, "<leader>w", ":w<CR>"
config.map :normal, "gd", :lsp_definition
config.leader " "
config.theme :carat_dark
config.lsp :ruby, command: ["ruby-lsp"]
```

The API only stores data into the existing `Options`, `Keymap`, and service registries. No DSL magic, no `instance_eval` of user blocks. A compiled Spinel build ships without the loader and uses built-in defaults; a later change can compile a config file in.

## 9. Testing strategy

- Unit tests with `minitest` from the standard library for `model`, `input`, and `commands`. Motions and operators are tested as tables: buffer text, cursor, keys, expected text, expected cursor. These tables double as the compatibility record for the Neovim behavior Carat implements.
- Renderer tests compare a `Frame` to an expected grid of strings. `Screen` tests check the ANSI byte output for a known frame diff.
- Editor tests drive a full `Editor` with a `FakeTerminal`: feed keys, assert the resulting frame and buffer. This is the main integration level and runs in milliseconds.
- Terminal smoke tests run the real binary inside a pseudo-terminal, as the earlier prototype did, to catch raw mode and escape sequence problems. They are few and slow.
- Compatibility check for the Spinel path: a `rake spinel:check` task compiles `lib/carat/core` with Spinel when the compiler is present and reports the first unsupported construct. It is advisory until the native build becomes a release target.
- RuboCop with a configuration that forbids the constructs listed in section 2 inside `lib/carat/core`.

## 10. Repository layout

```
bin/carat                  entry point
lib/carat.rb               requires core and, on CRuby, host
lib/carat/version.rb
lib/carat/core/
  app/        editor.rb loop.rb options.rb messages.rb
  input/      key.rb key_decoder.rb mode.rb keymap.rb command_parser.rb
  commands/   motions.rb text_objects.rb operators.rb dispatcher.rb
              ex/parser.rb ex/registry.rb ex/*.rb
  model/      buffer.rb position.rb range.rb cursor.rb selection.rb
              transaction.rb undo_tree.rb registers.rb marks.rb search.rb
  view/       window.rb layout.rb renderer.rb frame.rb cell.rb screen.rb theme.rb
  syntax/     tokenizer.rb ruby.rb markdown.rb json.rb yaml.rb plain.rb
  ports/      terminal.rb clock.rb file_system.rb service.rb
lib/carat/adapters/
  ansi_terminal.rb fake_terminal.rb real_clock.rb fake_clock.rb
  disk_file_system.rb memory_file_system.rb
lib/carat/host/
  config.rb process_runner.rb watcher.rb
  lsp/client.rb lsp/protocol.rb
  formatter.rb finder.rb explorer.rb git.rb
test/
  unit/       mirrors lib/carat/core
  editor/     full-editor tests with FakeTerminal
  smoke/      pty tests against bin/carat
docs/
  architecture.md          this document
  compatibility.md         the table of implemented Neovim commands
openspec/                  specs are the behavioral source of truth
```

## 11. Roadmap as OpenSpec changes

Each item is one OpenSpec change and one pull request, in this order. Each leaves the editor usable.

1. `editor-foundation`: ports and adapters, `Buffer` with the four primitives, `KeyDecoder`, `Editor` and `Loop`, `Renderer` and `Screen` for a single window, normal and insert modes with `h j k l i a o x dd`, command-line mode with `:w :q :wq :e`, and the test harness with `FakeTerminal`. This reproduces the earlier prototype on the new structure.
2. `command-grammar`: `CommandParser`, counts, registers, the full motion set, the first operators (`d c y p`), and text objects. The compatibility table starts here.
3. `undo-and-registers`: `Transaction`, `UndoTree`, `u`, `Ctrl-R`, the dot command, numbered and named registers.
4. `visual-modes`: charwise, linewise, and blockwise visual mode with operators applied to selections.
5. `search-and-substitute`: `/ ? n N * #`, `hlsearch`, `incsearch`, `:s` with ranges and flags, `:g` and `:v`.
6. `buffers-windows-tabs`: the buffer list, splits, `Ctrl-W` commands, tab pages, and the related ex commands.
7. `syntax-highlighting`: tokenizer interface, Ruby tokenizer, themes, 256-color and truecolor output.
8. `options-and-config`: `:set`, local options, the config file and `config.map`.
9. `lsp-client`: the host service runner, `ruby-lsp` integration, diagnostics in the sign column and as virtual text, go-to-definition, hover, completion menu.
10. `finder-and-explorer`: fuzzy finder and the file tree.
11. `formatting-and-git`: RuboCop formatting, git signs and status.
12. `native-build`: the Spinel build target, the compatibility check task, and the compiled-in defaults.

## 12. Decisions and alternatives

| Decision | Chosen | Alternatives considered | Why |
| --- | --- | --- | --- |
| Runtime | CRuby, core kept Spinel-compatible | Spinel only; CRuby only with gems in core | Keeps a native binary possible at the cost of a few coding rules; gems in the core would close that door |
| Text storage | Array of line strings | Rope; piece table | Simplest thing that handles the target file sizes; edits are behind four primitives, so it can change later |
| Key representation | Integer codes | Symbols; structs | Spinel-friendly, cheap to compare, trivially storable in keymap tries |
| Command handling | Parser produces a value, dispatcher executes | Handlers mutate state while parsing | Pure parsing makes the dot register, macros, and tests straightforward |
| Rendering | Full frame then diff | Incremental region updates | A frame diff is simple to reason about and already minimal in bytes; full frame computation is cheap at terminal sizes |
| Highlighting | Hand-written line tokenizers | Tree-sitter | No native extension in the core; richer highlighting can arrive as a host service |
| IDE features | Host services over ports | Built into the core | The core stays compilable and testable; services are optional and replaceable |
| Config | Ruby file with a data-only API | Vimscript subset; YAML | Ruby is the project language; a data-only API avoids metaprogramming and keeps the compiled build possible |
| Concurrency | Single-threaded loop with `IO.select` | Threads per service | One thread keeps the core deterministic and Spinel-compatible; subprocess pipes fit `IO.select` |
