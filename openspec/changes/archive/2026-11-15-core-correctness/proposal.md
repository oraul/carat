# Proposal

## Why

Four editing paths disagree with their sibling paths and with Vim. Tab under `expandtab` pads from the code-point column, so after a tab or a wide character it stops off the tab stop. A `none` unbinding walks the keymap trie with `child_for`, which creates the nodes it walks, so `keymap.normal xy none` turns `x` into an empty prefix that waits for a second key. `Buffer#revert_to` moves the lines and the signs back but not the marks of a running `:g`, which `splice` moves for every forward edit, so a plugin edit reverted inside `:g` leaves the marks on the wrong rows. `HandleKey#timeout` runs only the signature and prompt follow-ups of `HandleKey#call`, so a binding resolved after timeoutlen that moves the cursor leaves the documentation float, the completion menu, the definition float, or the palette as they were.

## What Changes

- `InsertTab` pads to the next tab stop from the display column of the cursor (`Domain::DisplayWidth.column`), as the rendering and the block operators measure it.
- `Keymap#bind_owned` with no value (a `none` line) walks only the nodes that exist and removes the nodes left with neither a value nor children, as `remove_owner` does; unbinding keys that were never bound creates nothing.
- `Buffer#revert_to` moves the global marks back with each record it undoes, beside the signs and the syntax cache, as `splice` moves them forward.
- `HandleKey#timeout` runs the same follow-ups as `HandleKey#call` after it dispatches: completion, hover, definition, signature, palette, and the plugin prompt, through one private method both use.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `insert-mode`: expandtab pads by display column.
- `keymap-config`: a `none` unbinding leaves no empty prefix, and a binding resolved by timeoutlen is followed as a typed key is.
- `global`: a reverted edit keeps the marks on their lines.

## Impact

- `carat/use_cases/insert_tab.rb`, `carat/domain/keymap.rb`, `carat/domain/buffer.rb`, `carat/use_cases/handle_key.rb`.
- `test/editor_insert.rb`, `test/domain_keymap.rb`, `test/domain_global.rb`, `test/editor_leader.rb`: the rows that fail before and pass after.
- `docs/codebase-map.md`: unchanged, no file is added, moved, or removed.
- README.md: unchanged, it describes Tab, `none`, `:g`, and timeoutlen as they behave after this change; the fixes restore what it says.
- docs/architecture.md: unchanged, the layers, the edit path, and the keymap design it records stay as they are.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.

Roadmap: outside the roadmap's feature order; it is a T6 fix from the periodic quality review, sprint 7's last queue item.

## Out of scope

- The key hints float after a timeout, which the brief does not name: `HandleKey#timeout` keeps not calling `HideKeyHints`.
- Any change to `remove_owner`'s pruning or to the trie's node layout.
- Display-column handling of other insert-mode keys (Backspace over expanded spaces, `softtabstop`), which carat does not implement.

Assumptions recorded here instead of asked: the `:g` revert row drives the buffer the way `GlobalCommand#visit` and `BufferRequests#edit_buffer` do (marks set, a transaction open, records undone by `revert_to`) in `test/domain_global.rb`, which tests the marks at the buffer, since no plugin double raises inside an edit request. A `none` line for keys that are a prefix of other bindings keeps those bindings, as Vim's `:unmap` of a prefix leaves longer mappings.
