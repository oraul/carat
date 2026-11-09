# Design

## Context

Scout packs at c1b3a12 (grammar and keymap, rendering, configuration). `HandleKey#step` returns `:waiting` for a lone prefix in a grammar mode and `:pending` for a prefix that is also bound or any prefix elsewhere; `InputController#handle` arms a `timeoutlen` deadline only for `:pending`. `KeymapNode` exposes no list of children. Action descriptions are the third argument of `ActionTable#register` (leader layout); group names exist only as a comment in `config/default.caratrc`; ex commands have none. Floats are `FloatWindow`s opened through `OpenFloat` and closed through `CloseFloat`, painted by `FramePresenter` with no cost when the tab page has none; `ShowSignature` is the shape of a float built from lines and reopened when its content changes. The command line already carries two prompts besides `:` (a search prompt and a plugin's prompt), each a record `ExecuteCommandLine` and `FramePresenter#command_prefix` consult.

## Goals / Non-Goals

**Goals:**

- One integer comparison per key for each feature while nothing shows; no allocation on the hot path; the clock read for the hints only where `timeoutlen` already reads it.
- Hints and palette read the descriptions from the tables the handlers registered, never a second copy.

**Non-Goals:**

- A hints float for a scratch buffer's keymap, or in insert and command-line modes.
- Ranking by use frequency, or a palette remembering its last text.

## Decisions

### The hints timer lives in InputController beside the timeoutlen deadline

`handle` already knows each key's result; it arms `@hint_at` when the result is `:waiting` and the delay is above 0, reading the clock as it does for the `timeoutlen` deadline of a `:pending` key. A `:pending` key (bound, and the start of a longer binding, or any prefix in insert and command-line modes) gets no hints: `timeoutlen` resolves it 200 ms after the default delay, so hints would flash and vanish, and the insert-mode waits would wake twice. `next_timeout` waits for the deadline or the hint time, whichever is armed; `pump`, on a read that times out with the hint due and keys still pending, calls `ShowKeyHints`. Alternative: a `Key::HINT` pseudo-key through `HandleKey`, as `TIMEOUT` is. Rejected: the hints change no input state, and a second pseudo-key would need its own branch in `HandleKey#call` for no gain.

### The hints read the trie, the action table, and a group name on the node

`Keymap#node_at(mode, codes)` walks the trie as `lookup` does and answers the node (an empty one when absent). `KeymapNode` gains `group` (a String, "" when unnamed) and `child_keys` (its children's decimal keys in insertion order, which is the configuration's order). `ShowKeyHints` builds one row per child: the key by `KeyNotation.format`, then `ActionTable#describe` or the plugin host's description for an action, the replayed text for a key sequence, or the child's group (or `+N`, the number of bindings under it) for a prefix. Rows are laid in columns of the room above the message row, the float anchored to the editor at its bottom right with z 950 (above the signature and documentation floats). `KeyHints`, a `Struct` record, keeps the float id for `HideKeyHints`, which `HandleKey#call` runs first when the id is not 0.

`keymap.group <keys> <name>` is read by `Keymap#apply` before the mode name, binding nothing: it creates the nodes of the keys in normal mode and sets the last node's group. Alternative: a new `keyhints` scope. Rejected: the group names a keymap prefix, and a `keymap` line keeps the leader expansion, the later-line rule, and the problem messages of the bindings. `Config#binding?` lets a group line through from a project file, since it replays no keys.

### The option is option.keyhints.delay

The parser splits a key at its first dot, so the option's name is `keyhints.delay`; `Options` stores it as `keyhints_delay` and checks the range 0 to 10000 as `tabstop` is checked.

### The palette is a prompt of the command line plus a menu float

`OpenPalette` builds the entries once per opening into the `Palette` record (parallel `names`, `keys`, `descriptions` arrays of Strings): the core actions in registration order, the enabled plugins' actions, then the ex commands as `:name`; each action's key is the first normal-mode binding found by a depth-first walk of the trie (built into a `Hash[String, String]` once per opening). It sets command-line mode with an empty text and marks the palette active. `FollowPalette`, run by `HandleKey#call` only while the palette is active or its float shows (one boolean test otherwise), refilters when the text changed, keeps the selection in range, and reopens the float when the shown text or selection changed; it closes the float and clears the palette when the mode left the command line. `FramePresenter#command_prefix` shows `>` while the palette is active.

Enter is `cmdline.execute`: `ExecuteCommandLine`, when the palette is active, takes the selected entry; an ex command runs through the `CommandRunner` as a typed line would (without joining the history), and an action is left in `Palette#chosen`, which `HandleKey` hands to its own dispatch with no keys, so it goes through the grammar exactly as its key would. Alternative: the palette as a focused scratch-buffer float with a plugin-style keymap. Rejected: typing the filter needs a text field, which the command line already is, with Backspace and Esc working unchanged.

`<C-n>` and `<C-p>` in command-line mode are `palette.next` and `palette.previous`, which move the selection and do nothing outside the palette. The command-line `<Up>` and `<Down>` stay the history keys.

### The fuzzy match is the completion popup's

`FuzzyMatch.score` already ranks completion candidates: the typed text's first byte (and each part after `_`) anchored at a part start, a prefix bonus, a bonus per consecutive byte, and the shorter word first. The palette scores an entry as the better of its name's and its description's score, after dropping a leading `:` from the typed text, and sorts the matching indexes by a stable insertion. Alternative: a second scorer tuned for dotted names. Rejected: one fuzzy rule across the editor, and the part-start anchor already treats `.` and spaces as starts.

### Ex descriptions live in ExTable

`ExTable#describe(full_name)` answers from a table keyed by the full name, so the handlers' registration stays unchanged; a test checks every registered ex command has a description of 1 to 32 characters, as `use_cases_actions` checks the actions.

## Risks / Trade-offs

- [The palette float is reopened on each typed key, a few hundred allocations per key while it shows] → Only while the palette is open; no cost when closed, which the benchmark holds.
- [A key binding found by the depth-first walk may not be the most familiar key of an action] → The walk follows the configuration's order, so the first line binding an action wins, which is the main key in the shipped file.
- [Running a grammar action from the palette with no keys leaves the repeat record without keys] → The dot command repeats by the command, not the keys; a test runs an operator from the palette.
