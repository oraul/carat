# Design

## Context

See proposal.md for the motivation. The review was made read-only on 8ac13c2; every finding was checked again on 59d818c, after `edit-pipeline`:

| Finding | State on 59d818c |
| --- | --- |
| H1 errors outside `StandardError`, unguarded `register` | open: six `rescue StandardError` blocks, `register` and `ManifestCheck.check` unguarded |
| H2 re-entry through `buffer_save` | open: `SaveFile#write` calls `saved`, which delivers at once, inside any plugin call |
| H3 positions instead of ids | half done: buffers have ids since `edit-pipeline`, but the API and the events still use list positions and layout numbers; windows have no id, and layout node ids are reused |
| H4 half-applied edits | half done: `edit_buffer` already runs inside one transaction from `edit-pipeline`, but items are not type-checked, so a bad last item raises after the later items landed |
| H5 lossy events | open: events still come from diffing the current buffer's change counter |
| M1 shared strings | open: `copy` copies the array, not the strings |
| M2 cleanup on disable | open: only the status segment is removed |
| M3 request shape | open |
| M4 loose checks | open: any minor and any older major accepted, duplicates pass |
| M5 signs on fixed rows | open, recorded in `docs/backlog.md` by `edit-pipeline` |
| M6 references without a require | open |
| L1 to L4 | open |

Nothing was fully fixed by `edit-pipeline`; H4 keeps its transaction and gains validation and a rollback. Spinel facts this design relies on, beyond those of the earlier designs: `rescue StandardError, ScriptError, SystemStackError` catches `NotImplementedError` and a runaway recursion on the pinned compiler (probed), a module included in several classes with a method that yields inside `begin`/`rescue` works, a signature on such a method is not applied and warns while `# @rbs skip` is silent, and `freeze` and a `FrozenError` behave as in Ruby.

## Goals / Non-Goals

**Goals:**

- No plugin can end the editor, recurse without bound, or leave a buffer half-edited; every plugin call goes through one guarded path.
- Ids instead of positions everywhere a plugin sees a buffer or a window.
- Events from the edit path with ranges, for every buffer, seen by every other plugin.
- The host as small classes by request family, each under about 250 lines, that a JSON-RPC gateway can map onto later.
- `make diagnose` clean and no new `untyped` in `make types` beyond the documented `Array[untyped]` lists.

**Non-Goals:**

- The JSON-RPC layer and `docs/plugin-protocol.md`; removing `attach`; a typed `FilePort#stat`; the selection request and the unfocused tree cursor (both stay in the backlog); `idle`.

## Decisions

### One guarded path, as a concern

`UseCases::Guarded` (`carat/use_cases/concerns/guarded.rb`) has one method, `guarded(entry)`, which tells the registry a call into the plugin begins, yields, rescues `StandardError`, `ScriptError`, and `SystemStackError`, tells the registry the call ended, disables the plugin with the error's message when it raised, and answers whether the call completed. It depends on one reader, `registry`, and keeps no state: the depth and the current cause live in `PluginRegistry`. It is included by `PluginRegistry` (whose `registry` answers itself), `PluginRouter`, and `PluginEvents`, which make every call into a plugin: the manifest read and its check, `activate`, `deactivate`, `on_event`, `on_action`, `on_command`, and `on_input`. Its method carries `# @rbs skip`, because a signature on a mixed-in method is not applied. The alternative, a method on the registry taking a block, works as well; the concern was asked for and fits the rules (no instance variables, no constructor, one reader).

A manifest that raises registers the plugin disabled under `plugin<N>`; a manifest whose members have the wrong types is caught by `ManifestCheck`, which now checks each member's type (`actions is not an object of action names`, and so on) before using it, and by the guard around the check for anything it misses.

### Depth, cause, and the event queue

`PluginRegistry` keeps `depth` and a stack of plugin names; `enter(name)` pushes and sets the state's buffer feed's `cause` to the name, `leave` pops and restores it. `PluginEvents` keeps a queue of `PendingEvent` records (an event and its cause). Events are queued, never delivered from inside a plugin call. `PluginHost`, the facade every other use case calls, flushes the queue at the end of each of its entry points when the registry's depth is 0 (`register`, `activate_all`, `action`, `command`, `answer`, `observe`, `resized`), so the outermost call delivers. `saved` only queues: a write from the command line is delivered with the other events of the key, after the command has shown its message, so a message a plugin shows on a save, or the rounds limit, is not overwritten by the written message. `flush` moves the feed's notices into the queue and delivers round by round: a round takes the whole queue, delivers each event to every enabled subscriber except its cause, and what those deliveries queue forms the next round. After `MAX_ROUNDS` (8) rounds the rest is dropped with "Plugin events dropped after 8 rounds". A `flushing` flag keeps a flush from starting inside another.

`run_ex` refuses with "E169: Command too recursive" (Vim's message for the same condition) when the registry's depth is `MAX_DEPTH` (4) or more, which bounds a plugin command that runs itself; every other request either makes no plugin call or only queues events.

The alternative, delivering at once with a re-entry flag that drops nested events, is what Neovim does for non-nested autocommands, but it is the bug H5 describes: other plugins never see what one plugin did.

### Events from the edit path

`Domain::BufferFeed < Struct.new(:cause, :notices)` is the one sink for buffer events, owned by `EditorState` (`feed`) and handed to every buffer that enters the list (`Buffer#feed`). It records `BufferNotice` records (`kind`, `buffer_id`, `row`, `removed`, `inserted`, `path`, `detail`, `cause`): `"open"` from `add_buffer`, `"close"` from `drop_buffer`, `"rename"` from the new `Buffer#rename(path)` (used by `SaveFile` for an unnamed buffer and by `FileOps` when a renamed file's buffers follow), and `"change"` when a transaction with records closes. `PluginEvents` turns each notice into a `PluginApi::Event`. A `"close"` is delivered only for a buffer whose `"open"` was delivered (a `Hash[String, bool]` of announced ids), so the empty buffer the editor starts with and replaces before any plugin sees it produces nothing. This replaces the `known?` and `prune` scans, which compared every listed buffer with every known one after each key.

`Transaction` gains `cause`: the feed's cause when its first record is added, and `""` (the editor's) once a record with another cause joins, so the join of a plugin edit into the command of the key bound to it stays the plugin's, while an insert session a plugin edited during counts as the user's. A transaction's range is the merge of its records: with the span so far at row `s` with `rem` rows removed and `ins` inserted, a record at row `a` removing `r` and inserting `i` gives `s' = min(s, a)`, `e = max(s + ins, a + r)`, `rem' = e - (ins - rem) - s'`, and `ins' = e + i - r - s'`. Rows between two records that did not change are inside the span, which is what a plugin re-reading the span needs.

`cursor_move`, `mode_change`, and `window_focus` still come from comparing the state after a key with the last snapshot, now by buffer and window id.

### Ids

Buffers already have ids. `Window` gains an `id` member; `EditorState` gains `next_window_id` and `adopt(window)`, which gives a window with id 0 the next id, called for the first window, by `add_tab`, by `SplitWindow` for the window `Layout#split` made, and by the side split. Layout node ids stay internal, since a freed node slot is reused. `EditorState#window_tab(id)` finds the tab page of a window id and `Layout#leaf_of(id)` its leaf, both linear walks over a handful of windows; `Layout#leaf_showing(buffer)` replaces the host's `window_showing`. A window id of another tab page is focused as `win_gotoid` does, by switching tab page first. Buffer ids are resolved with `EditorState#buffer_with_id`.

### Edit requests

`BufferRequests#edit_buffer` first checks every item: an `Edit`, a `String` text, positions inside the buffer, an end not before its start, ascending and not overlapping; the first problem refuses the request with the item's number. Then it opens (or joins) the transaction, applies the items from the last to the first, and on any raise rolls back with the new `Buffer#revert_to(count)`, which undoes the open transaction's records after `count` in reverse order without recording, restores the change counter, and moves the signs back. A rolled-back request that opened its transaction leaves an empty one, which closes without a record and so without an event.

### Strings at the boundary

`BufferView#lines`, `Event#path`, `Context#path`, and `BufferView#path` are copies; the lines a plugin gives `open_scratch` and `set_scratch_lines` are copied before they enter the buffer. The line copy is `Boundary.copied_lines`, a module function rather than a second concern, because a concern's method gets no signature and its result widened to `Array[untyped]` in `make types`. Freezing the buffer's own strings in place was the cheaper alternative, but a hidden in-place mutation anywhere in the core would then raise; copying costs one allocation per line read, which the explorer's few dozen lines do not notice.

### Cleanup on disable

`PluginRegistry#disable` marks the entry, records the reason, shows the message, and then removes what the plugin left: its status segment, its open prompt (cleared with the command line, back to normal mode, no `on_input`), its signs in every listed buffer, its scratch buffers (every window showing one is closed through `CloseWindow#remove` in its tab page, and when that would close the last window of the editor the window shows a new empty buffer instead), and its key bindings, through `Keymap#remove_owner(name)`. `KeymapNode` gains `owner`; `Keymap#add_owned(keymaps, leader, owner)` records it and refuses keys another owner holds, which is how binding conflicts are reported; the configuration's bindings are added with the empty owner, replace a plugin's, and are never removed with it.

### Signs as layers

`Buffer#signs` and `Buffer#sign_owners`, keyed by row text, become `sign_layers`, an `Array[untyped]` of `SignLayer` records read through `layer_at(i)`: the owner, its priority (the registration index), the glyphs it uses, and `marks`, an `Array[Integer]` with one entry per line (0 for none, k for the k-th glyph). `Buffer#splice` moves every layer by the record through `LineSplice.shift_marks`, a sibling of `LineSplice.apply` over integers: the rows both sides have in common keep their marks (so editing a line keeps its sign), extra inserted rows get 0, and extra removed rows lose theirs. `Buffer#sign_at(row)` answers the glyph of the layer with the lowest priority number that marks the row. Layers are kept sorted by priority, so the lookup is a walk over a few layers.

### The request shape (M3)

Done now: strings instead of symbols for events (`PluginApi::EVENTS`), option types (`OPTION_TYPES`), and sides (`"left"`, `"right"`); `WindowResponse` (`ok`, `message`, `window`) for `open_scratch`, `focus_window`, `open_file`, `open_in_split`, `open_in_tab`, `editing_window`, and `scratch_window`; `TextResponse` (`ok`, `message`, `text`) for `icon`, `option`, and `working_directory`; `BufferView` with `message` and `buffer` (the id). `Response` stays the general answer. A 1.1 manifest listing symbols is converted with `to_s` when it registers.

Planned for `plugin-protocol`, not built: the request table. Each host method becomes one row of a constant table in `plugin_api.rb` (`["read_buffer", "BufferView", ["buffer:Integer"]]`, and so on), from which the JSON-RPC gateway decodes a request into the positional call and encodes the typed response, and against which the lint test checks that `Host` and `PluginLink` define exactly the listed methods. Every value is already a `Data` value of strings, integers, booleans, and string arrays, so each has a JSON form.

### The split

| Class | File | Owns |
| --- | --- | --- |
| `PluginHost` | `plugin_host.rb` | the facade the core calls: register, activate, attach, route, observe, saved, resized, the flush after each top-level call |
| `PluginEntries` | `plugin_entries.rb` | the entry list with an `Hash[String, Integer]` index and a typed `find` |
| `PluginRegistry` | `plugin_registry.rb` | guarded register and activate, the version and uniqueness rules, options, binding merge, refusal, disable with cleanup, depth and cause |
| `PluginRouter` | `plugin_router.rb` | actions, ex commands, prompt answers |
| `PluginEvents` | `plugin_events.rb` | queue, rounds, delivery, the snapshot comparison |
| `BufferRequests` | `buffer_requests.rb` | read, edit, cursor, signs |
| `WindowRequests` | `window_requests.rb` | scratch buffers, focus, open file, split, tab, editing and scratch window |
| `FileRequests` | `file_requests.rb` | list, stat, and the four file operations through `FileOps` |
| `UiRequests` | `ui_requests.rb` | message, status, prompt, icon, option, working directory, run_ex |

`PluginLink` holds the registry and the four families; each method checks the refusal once and forwards with the plugin's name. Every family holds the one state handle it was built with; no method takes a second `state`. `FileOps` (`carat/use_cases/files/file_ops.rb`) owns the checks and the port calls of make, rename, and delete, `follow_rename`, the deleted-buffer marking, and `probe(path)`, the one place that wraps `FilePort#stat` in a rescue and returns a `Domain::PathInfo`; the pure rules (a name's problem, containment) are `Domain::PathPolicy`. `SplitWindow#side` adds a fixed-width window at the edge and numbers it; `place_side` is gone. `Keymap.action_name?` is the one regex both `HandleKey` and `ManifestCheck` use. The helpers are renamed as they move: `int_of` is gone with `probe`, `known_at` with the feed, `path_of` becomes `Buffer#path_text`, `edit_at` becomes `edit_item`, and `copy` becomes `copied_lines`.

### Ordering in the assembly

`EditorAssembly` registers the plugins, builds `ExecuteEx` and attaches it, then activates, so `run_ex` works in `activate`. `attach` itself stays until the dependency-injection change.

### Lint

`test/lint.rb` gains: the plugin reference rule (a line under `carat/plugins/` naming `Domain::`, `UseCases::`, `Adapters::`, `Drivers::`, or `Doubles::` outside a comment is a violation); the `PluginLink` coverage rule (every `def` of `PluginApi::Host` has a `def` in `plugin_link.rb`); and the concern rules for `carat/<layer>/concerns/` (a `Readers:` line at the top, every method marked `# @rbs skip`, no instance variable, no `initialize`, no `extend`, no `included do`, no `define_method`). Each rule is a function, and the lint program also asserts each against a known good and a known bad line, so a broken rule fails the suite instead of passing silently. The layer rule needs no change: a concern's layer is the directory above it.

## Risks / Trade-offs

- [The API version stays 1.x although some changes break a 1.1 plugin] → the only plugins live in this repository and change with it; symbols in a manifest are still accepted; recorded in the proposal and in `docs/plugins.md`.
- [A plugin no longer hears the events its own requests cause] → the explorer follows through `cursor_move` and `window_focus`, which come from the snapshot after the key and still reach it; the editor tests of the explorer prove it unchanged.
- [`buffer_change` arrives only when a transaction closes] → an insert session is reported once on Escape; a plugin that needs every keystroke waits for a later `text_changed_insert` style event.
- [Sign layers cost one integer per line per plugin with signs] → a few hundred kilobytes on 100,000 lines for the git signs plugin; the shift is the same tail move as the lines.
- [Rounds can drop events] → only under a ping-pong between plugins, reported in the message row.
- [The split adds files] → each class has one reason to change and the facade keeps every caller's interface.

## Migration Plan

Plugins in this repository move to 1.2 in the same change. Rolling back is reverting the squash commit; there is no data or configuration migration.
