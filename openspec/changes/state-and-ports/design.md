# Design

## Context

See proposal.md. Every finding was checked again on 7cc05e0, after `dependency-injection`:

| Item | State on 7cc05e0 |
| --- | --- |
| 1 `EditorState` | 452 lines and 22 members; 26 use case and adapter files reach its buffer list, tab list, input, register, find, or plugin members |
| 2 attach | `PluginHost#attach` and `UiRequests#attach` tie the ex runner in after construction; `UiRequests` keeps an `ExecuteEx?` |
| 3 configuration | `bin/carat.rb` calls `JsonConfigGateway#load` and passes the hash with `config_source:`; the assembly falls back to `"\\"` and 1000 |
| 4 signals | `MainLoop` reads `Signals.terminated` and `Signals.resized`, module-level flags |
| 5 stat | `FilePort#stat` returns a hash of integers; `FileOps#probe` converts it into `Domain::PathInfo` with a `field` helper |
| 6 doubles | `carat.rb` requires the five doubles, so `build/bin/carat` contains them |
| 7 constructors | 18 files on `PENDING_CONSTRUCTORS` |
| 8 shared instances | no test; a keyword default would silently build a second object |

Spinel facts this design relies on, beyond those of the earlier designs, probed on the pinned compiler for this change: a `Signal.trap` block in an instance method may assign the instance's own variables, and a method reading them through a base-class reference sees the change; a `# @rbs @member: Name?` pin on a `Struct` record may name a class defined in a file required later, without requiring it, and calls through the member are resolved.

## Goals / Non-Goals

**Goals:**

- Each use case and adapter receives by keyword only the records and collaborators it uses, built once in `EditorAssembly`, and the shared-instance test proves each is one object.
- No cycle is broken after construction: no `attach`.
- The production require graph holds no double.
- Behavior, every editor snapshot, and key handling time unchanged (within 10 percent on the benchmark); `make diagnose` clean; no member of the new records widens in `make types`.

**Non-Goals:**

- Removing `EditorState` entirely or changing the input ports' `call(state, ...)`.
- Making motions pure (the backlog item stays, with its outline updated to the find record).

## Decisions

### The records

All are `Struct` records in `carat/domain/`, each member pinned, empty collections stored through the writers after `super()`.

- `BufferList < Struct.new(:tabs, :buffers, :next_id, :feed)`, built with the tab list: the listed buffers in order (`buffer_at`, `count`, `index_of`, `number_of`, `for_path`, `with_id`, `scratch_for`), the ids (`add` gives a buffer with id 0 the next one), the feed it hands every buffer it lists and records opens and closes in, and the policy: `remove`, `release` (an unmodified or scratch buffer no window shows leaves the list), `hidden_modified`, `modified_buffer`, `any_modified?`, and `load` (show a buffer in the current window, listing it and letting the old one go). The policy needs to know which windows show a buffer, so the list holds the tab list; nothing in the tab list needs the buffer list.
- `TabList < Struct.new(:pages, :tab_index, :next_window_id)`, built with the first window: `tab`, `window`, `tab_at`, `tab_count`, `add_tab`, `remove_tab` (the alternate tab rule of Neovim's `alt_tabpage`), `next_tab`, `previous_tab`, `adopt` (window ids), `window_tab`, `total_windows`, `shown?`, and `clamp_cursors`.
- `InputState < Struct.new(:pending_keys, :grammar)` with `pending?` and `take_keys`.
- `LastFind < Struct.new(:entry)` with `remember`; `Motions.for_command` takes it beside the state, and `Move` and `Operate` receive it.
- `PluginUi < Struct.new(:segments, :prompt, :prompt_owner, :prompt_id)` with `prompting?`, `open_prompt`, `close_prompt`, `segment`, and `drop`.
- `Options` gains `timeoutlen` (Vim's 1000 by default) and `from_config` takes the whole configuration value, reading `options` and the top-level `timeoutlen`.
- `Registers` is unchanged and leaves the state; `Operate` and `OperateOnSelection` receive it.

`EditorState < Struct.new(:tabs, :mode, :options, :cmdline, :message, :message_error, :quit, :block_insert)` is built from the tab list and the options. It keeps the current view (`tab`, `window`, `buffer`, `cursor`, `current_line`, `max_col`, `selection`, `end_visual`) and the message (`show`, `clear_message`). The tab list is a member because the current view is reached through it; the buffer list is not, so a use case that lists, releases, or finds buffers must be given the list. The alternative of removing the aggregate means a new signature for every handler of both input ports, which is not this change.

### Wiring

`EditorAssembly` builds, in order: the tab list from a first window over an empty buffer, the buffer list over it (listing that buffer), the state, the options, the keymap, the registers, the last find, the input state, the plugin UI state, the ex table and `ExecuteEx` over it, the use cases, the plugin host (given the runner), the ex handlers (core first, the plugin command handler last), the action handlers, the dispatcher, `HandleKey`, the input controller, and the presenters. Each collaborator it builds is kept in an instance variable with a reader, so the shared-instance test (`test/adapters_assembly.rb`) can compare them with `equal?`. Each class that holds a shared object gets a reader for it. No constructor parameter for a shared object has a default; the lint rule against positional parameters and this test together guard the convention.

The keyword names: `buffers:` and `tabs:` for the two lists, `registers:`, `last_find:`, `input:`, `plugin_ui:`, `runner:` for the command runner, and the port names `terminal:`, `clock:`, `files:`, `config:`, `signals:`. In `PluginLink`, whose request families were positional, the families are `buffer_requests:`, `window_requests:`, `file_requests:`, and `ui_requests:` so they cannot be mistaken for the lists.

### Cursor clamping from the change records

`Buffer#close` already records a closed transaction with records in the feed as a change notice with its first row. `BufferFeed` gains a `tabs` member, the tab list `BufferList` sets when it is built, and `push` asks it to `clamp_cursors(buffer_id, row)` for a change notice: every window of every tab page showing that buffer whose cursor is on or below the row has the row brought inside the text, the column onto the line's last character, and a scroll position past the end reset, the rule `EditorState#clamp_cursors` applied before. Rows above the change are untouched, so their cursors stay valid. This replaces the explicit calls after `:e!`, a plugin edit, and a scratch refresh, and covers every other edit, such as `dd` of the last line in one window of a buffer another window shows. A transaction stays open for the insert session and is closed by `LeaveInsert` after the cursor moved back, and visual operators leave visual mode first, so a close never sees a cursor legitimately past the last character. A plugin edit joined to a key's transaction is clamped when that transaction closes, after the command, instead of right after the request.

### CommandRunner

`UseCases::CommandRunner` (`use_cases/ex/command_runner.rb`) has `call(state, text)` raising `NotImplementedError`, documented to return an `Outcome`; `ExecuteEx < CommandRunner`. The assembly builds the ex table empty, `ExecuteEx` over it, and gives the runner to the plugin host, which hands it to `UiRequests` at construction; the ex handlers are registered into the table afterwards, `PluginCommandHandler` with the finished host last. The table is the only thing filled late, and it is filled before any key or plugin activation can run a command. `EditCommandLine` receives the runner too.

### Configuration

`Ports::ConfigPort` has `load`, the parsed value, and `source`, the file name for configuration problems. `JsonConfigGateway` returns the embedded defaults and `config/default.json`; `FixedConfig.new(value:)` returns its value and the same name. The assembly takes `config:` as the port, calls `load` once, builds `Options.from_config(value)`, reads the leader with `Keymap.leader_from(value)`, and passes `value["plugins"]` and `value["keymaps"]` on. `config_source:` is gone. A missing value falls back to Vim's default inside the domain, never in the assembly.

### Signals

`Ports::SignalPort` has `install`, `terminated?`, `resized?`, and `acknowledge_resize`. `Drivers::Signals < SignalPort` keeps two instance flags that its `install` traps assign (INT and TERM terminate, WINCH resizes); `bin/carat.rb` builds and installs it before the first thread. `Doubles::ManualSignals` has `resize`, `terminate`, `terminate_after(polls)` (terminated after that many polls), and counts `installs`, `polls`, and `acknowledged`. `MainLoop.new(assembly:, terminal:, signals:)` loops until the state quits or `terminated?`, and redraws and calls `acknowledge_resize` when `resized?`. `test/drivers_main_loop.rb` runs the loop over the harness: a tripped resize is acknowledged and redrawn once, `terminate_after` ends the loop, and `:q<CR>` typed through the fake terminal ends it through the state.

### The stat value

`FilePort#stat(path)` returns `Domain::PathInfo` (exists, size, mtime, directory following a link, symlink): `PathInfo.missing` for a path where nothing is, a link to nothing included as an existing link of size 0. `DiskFiles` and `MemoryFiles` build it; `FileOps#probe` returns the port's value and keeps its rescue for a port that raises (permissions), so the `field` helper goes.

### Test-support graph

`carat.rb` ends with the drivers and the plugin registry and no longer requires a double. `carat/test_support.rb` requires `../carat` and the six doubles; every test program that uses a double requires it, and a benchmark does the same. The lint test adds `double_require_problem(path, target)`: a `require_relative` resolving under `carat/doubles/` from a file under `bin/` or `carat/` is refused unless the file is itself under `carat/doubles/` or is `carat/test_support.rb`, with a good and a bad self-check. `carat/test_support.rb` has no layer, like `carat/testing.rb`.

### Constructors

The 18 pending files take required keyword arguments: `InputController`, `ScreenPresenter`, `Json`'s parser and writer, `FakeTerminal`, `AnsiTerminal`, `MainLoop`, `FileOps`, `OpenFile`, `Quit`, `BufferRequests`, `FileRequests`, `PluginEvents`, `PluginLink`, `PluginRegistry`, `UiRequests`, `WindowRequests`, `OpenTab`, and `SplitWindow`, and every class this change touches. `PENDING_CONSTRUCTORS` and its check are removed; the constructor rule now applies to every behavior class.

## Risks / Trade-offs

- [The feed calls the tab list on every closed transaction] → one walk over a handful of windows per command that edits; measured with `dd` on 100,000 lines below.
- [A plugin edit joined to a key's transaction is clamped at the end of the key] → a plugin reading the cursor between its edit and the end of the key may see a row past the end; `Buffer#line` answers `""` there, and no plugin of this repository reads it.
- [Readers added for the shared-instance test widen the public surface] → they are readers of collaborators already passed in; nothing writes through them.
- [Many constructor call sites in tests change] → mechanical, and the snapshots must not change.

## Migration Plan

None: no data, configuration, or plugin API change. Rolling back is reverting the squash commit.
