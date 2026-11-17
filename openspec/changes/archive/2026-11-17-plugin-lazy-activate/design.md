# Design

## Context

`EditorAssembly` calls `PluginHost#activate_all` once while wiring; `PluginRegistry#activate_all` resolves each enabled entry's options, merges its default bindings, and calls `activate` under the guard. Every path into a plugin (`PluginRouter#action`, `#command`, `PluginEvents#deliver`, `PluginSyntax#provider`) checks only the entry's `enabled` flag. git_signs' `activate` reads buffer 0 and runs git. The only idle point is `InputController#pump`, when a read times out with no key and no wait pending; the main loop draws a frame before its first pump, so that point is always after the first frame.

## Goals / Non-Goals

**Goals:**
- One rule for every compiled plugin, enforced by the host, with nothing for a plugin to opt into.
- No path reaches a plugin's `on_action`, `on_command`, `on_event`, or `tokenize` before its `activate` ran.

**Non-Goals:**
- Deferring the manifest read or the binding merge: the keymap and the ex table need them, and they run no plugin code beyond `manifest`.
- Process plugins.

## Decisions

- An `active` member on `PluginEntry`, false at registration. `PluginRegistry#activate(e)` returns false for a disabled entry, true for an active one, and otherwise sets `active` first (so a plugin that triggers itself from `activate` does not recurse), calls `activate` under the guard, and returns whether the entry is still enabled. Every trigger goes through it.
- `activate_all` becomes `prepare_all`: the configuration check, the options, and the bindings, no `activate`. The name says what it does now; the two callers in tests move with it.
- Triggers: `PluginRouter#action` and `#command` activate the owner before calling it (a key bound to a plugin action reaches the router, so keys need no path of their own); `PluginSyntax#provider` activates the first declaring entry and moves on to the next when that activation fails; prompts need nothing, since only an active plugin can open one.
- Events: `PluginEvents#deliver` and `#wanted?` skip an entry that is not active. Delivering the missed events at activation was rejected: the queue would grow without bound for a plugin never used, and `activate` can read the current state through the requests it already has.
- Idle wake: `PluginHost#idle`, called from the idle branch of `InputController#pump`, activates once, after a frame was drawn (`resized` is the host's draw-time call), every enabled entry that declares no action, ex command, or filetype, then flushes; it returns true when it woke one, so the loop redraws. Later calls return at once on a flag. A dedicated `idle` event was rejected: it is reserved for the language services change and would put the timing in each plugin instead of the host.
- `PluginHost#active?(name)` reports the flag, for the palette's future use and for the tests; `PluginHost#activate(name)` activates a plugin as its first trigger would, used by test rigs that exercise requests rather than triggers.
- API 2.9: no request changes, but when `activate` runs and which events arrive is part of what a plugin relies on, so the minor moves; `docs/plugins.md` records it.

## Risks / Trade-offs

- [A plugin with an action that also wants events from startup gets none until its first trigger] → the rule is documented in the template and `docs/plugins.md`; such a plugin reads the current state in `activate`.
- [Activation now happens inside a key or a draw, so a slow `activate` delays that key or frame] → the same cost moved from startup to first use, once; the bench scenarios run with the plugins as before.
- [A late `activate` that raises leaves its trigger without an effect] → the disable message says why, as for any other raise; the next key runs normally.
