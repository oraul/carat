## Why

In the file tree, Enter and `l` open a closed folder, but on an open folder they do nothing, so a folder cannot be closed the way it was opened; only `h` and `o` close it. In nvim-tree and VS Code Enter toggles a folder. The bug was reported by the user and reproduced in a terminal session of the built binary. It is outside the roadmap of `docs/architecture.md` section 12: a fix to the explorer half of item 12, already delivered.

## What Changes

- `<CR>` in the tree toggles a directory (expands a collapsed one, collapses an expanded one) and still opens a file in the editing window, as `o` does.
- `l` keeps its behavior: it expands a collapsed directory or opens a file, and leaves an expanded directory expanded.
- `h` and `o` keep theirs; the cursor stays on the directory's line after `<CR>`, `l`, `h`, or `o` on a directory, nested or not, and with the tree reached through Ctrl-W.
- The `?` summary reads `<CR>/o toggle  l open  h close ...`, and `docs/actions.md` lists `<CR>` under `plugin.explorer.toggle_dir` instead of `plugin.explorer.open`.
- Folded (periodic quality at 5b128b5): the uncalled `Tree#show_hidden?` is removed.
- The planner's records: `docs/queue.md` from the plan, its four backlog entries in `docs/backlog.md`, and the wrap-width backlog entry corrected to four comments.

Out of scope: any other tree key, the follow drift of an unfocused tree (`docs/backlog.md`), and a configurable tree keymap.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `file-explorer`: `<CR>` toggles a directory instead of only expanding it; the requirement on `<CR>` and `l` and the `?` summary scenario change.

## Impact

- Code: `carat/plugins/explorer/plugin.rb` (the tree keymap and the help line), `carat/plugins/explorer/tree.rb` (the dead reader).
- Tests: rows in `test/editor_explorer.rb` for each key and state, a nested directory, and the tree reached through Ctrl-W; the help row.
- Docs: `docs/actions.md`, `docs/backlog.md`, `docs/queue.md`.
- Per key: no change; the binding moves from one action to another.
