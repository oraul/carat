# Proposal

## Why

Carat has over 250 actions, 45 ex commands, and leader, `g`, `z`, and `Ctrl-W` key groups, but nothing in the editor shows them: a user who presses the leader and pauses sees no list of what may follow, and an action without a key, or one whose key is forgotten, can only be found in `docs/actions.md`. The leader layout gave every core action a short description for exactly this; the user put the remaining UI first, and this is its first item.

## What Changes

- Key hints: when keys that only begin longer bindings (the lone prefixes that wait with no time limit) wait `option.keyhints.delay` milliseconds (300 by default, 0 turns hints off) with no further key, a bordered float at the bottom right lists each next key with its action's description, or the group name of a key that begins more bindings, in columns when the list is taller than the screen. The next key, Esc included, closes it and is handled as usual; a binding still pending after it waits the delay again.
- Group names: a new configuration line `keymap.group <keys> <name>` names a normal-mode prefix for the hints; the shipped defaults name the leader groups (windows, quit, files, buffers, docs), `g`, `z`, and `Ctrl-W`.
- Command palette: `<leader>p` and `<F1>` in normal mode open a prompt `>` on the command line and a float listing every action (the core's and the enabled plugins') and every ex command, each with its normal-mode key and its description. Typing filters the list by a fuzzy match on the name and the description, best match first; `Ctrl-N` and `Ctrl-P` move the selection; Enter runs the selected entry as if its key had been pressed (an ex command as if typed after `:`), and Esc closes the palette.
- Ex commands get a short description each, as the actions have, held beside the ex command table.
- New actions `palette.open`, `palette.next`, `palette.previous` with rows in `docs/actions.md`; the option and the group line in `docs/compatibility.md`.
- No cost per key while neither shows: one integer comparison per key for each, no allocation; the timer reads the clock only when a key is already pending, as `timeoutlen` does.

Out of scope: hints in insert and command-line modes (their prefixes, such as `Ctrl-R`, wait on `timeoutlen` only); hints for a scratch buffer's own keymap; a palette over files (the finder item), symbols, or the command history; mouse selection in either float; descriptions for plugin ex commands; colors beyond the existing float and menu groups.

This change is not a numbered item of `docs/architecture.md` section 12: it is the first UI item of the T5 roadmap track in `docs/goals.md`, ordered first by the user.

Assumptions: the option is `option.keyhints.delay`, since every option line has the `option` scope; group names are a `keymap` line so they sit beside the bindings they name and a later line wins; the palette's prompt is the command line, as the search prompt and a plugin's prompt are, so editing keys work there unchanged.

## Capabilities

### New Capabilities

- `key-hints`: the float of next keys after a waiting prefix, its delay option, and the group names of prefixes.
- `command-palette`: the filterable list of every action and ex command, opened by keys, run by Enter.

### Modified Capabilities

None.

## Impact

- Domain: `KeymapNode` gains a group name and a list of its child keys; `Keymap` reads `keymap.group` lines and answers the node of a prefix; `Options` gains `keyhints_delay`; new `KeyHints` and `Palette`; the palette reuses the completion popup's `FuzzyMatch`.
- Use cases: new `ShowKeyHints`, `HideKeyHints`, `OpenPalette`, `FollowPalette`, `PaletteHandler`; `HandleKey` closes the hints and follows the palette; `ExecuteCommandLine` runs the palette's entry; `ExTable` describes each command.
- Adapters: `InputController` times the hints; `FramePresenter` shows the `>` prompt; `EditorAssembly` wires the pieces.
- Configuration: `config/default.caratrc` (the option, the group lines, three bindings) and its generated mirror.
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `README.md`.
