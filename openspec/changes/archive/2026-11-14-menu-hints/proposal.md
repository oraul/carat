# Proposal

## Why

The key hints float sits at the bottom right of the editor (`carat/use_cases/discovery/show_key_hints.rb:143`), away from where the eye rests, and a prefix no `keymap.group` line names reads as `+N` (`:97`), a count that says nothing about what the keys do. The hints code also carries four small faults: the default delay is a literal 300 beside the unused `Options::KEYHINTS_DELAY` (`carat/domain/options.rb:78`, `:95`), `ShowKeyHints#call` copies `HideKeyHints#call`'s close (`show_key_hints.rb:56`), `ShowKeyHints` and `HandleKey#grammar_mode?` each spell out the grammar-mode test (`show_key_hints.rb:61`, `carat/use_cases/handle_key.rb:218`), and `HandleKey#call` restates `KeyHints#showing?` as `float_id != 0` (`handle_key.rb:145`). This is part a of queue item `menu-hints` (sprint 3, the user's now-request), covering the backlog headings "KEYHINTS_DELAY is never read", "ShowKeyHints copies HideKeyHints' close", "Key hints repeat the grammar-mode test", and "HandleKey restates KeyHints#showing?". It is outside the roadmap of `docs/architecture.md` section 12: it finishes the delivered discoverability work.

## What Changes

- The key hints float is a centered bottom panel: horizontally centered on the screen (`FloatWindow#centered`, the palette's placement flag) and standing on the row above the message row less the float margin, at show and after a resize.
- A prefix no `keymap.group` line names shows a group name instead of `+N`: the first dotted segment every action under it shares (`<leader>xa cursor.up` and `<leader>xb cursor.down` read `x  cursor`), or `group` when the bindings under it share none (remaps, mixed actions).
- `Options` builds its default delay from `KEYHINTS_DELAY`.
- `ShowKeyHints` closes a shown hints float through `HideKeyHints` and holds no `CloseFloat` of its own.
- `Domain::Mode.grammar?(mode)` is the one grammar-mode test, read by `HandleKey` and `ShowKeyHints`.
- `HandleKey#call` asks `KeyHints#showing?` before hiding the hints.

Assumptions:

- "A centered bottom panel" is read as the hints' existing bordered float, sized to its rows as before, centered horizontally and kept at the bottom; not a full-width bar.
- "Named groups" is read as a name for every prefix row: the configured group name when there is one, else the shared first action segment, else the word `group`. A user who wants another name writes a `keymap.group` line, as before.
- The `screen_cols < 6` guard at `show_key_hints.rb:125` stays: removing it is `discoverability-tidy`'s.

Out of scope: the palette's rows, name column, and match spans, the selected rows' contrast, and the completion popup's padding (`palette-rows`, sprint 3 item 1).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `key-hints`: the hints float is centered at the bottom, and an unnamed prefix shows its shared action segment or `group` instead of `+` and a count.

## Impact

- Code: `carat/use_cases/discovery/show_key_hints.rb`, `carat/use_cases/handle_key.rb`, `carat/domain/mode.rb`, `carat/domain/options.rb`, `carat/adapters/editor_assembly.rb`.
- Tests: `test/editor_key_hints.rb`, `test/domain_mode.rb` or the nearest mode test, `test/adapters_assembly.rb`, and their snapshots.
- Docs: `docs/codebase-map.md` (area 5), `docs/compatibility.md` (the key hints paragraph).
- README.md: changed, the key hints sentence says the panel is centered at the bottom.
- docs/architecture.md: unchanged, it names the hints use cases and the option, not their placement or row text.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
