## Context

See `proposal.md` for the problem. The tree's keys are the plugin's own scratch keymap (`Plugin#keymap` in `carat/plugins/explorer/plugin.rb`), not lines of `config/default.caratrc`. `<CR>` and `l` both name `plugin.explorer.open`, which runs `open_entry(..., :edit)`: on a directory `Tree#expand`, on a file `open_path`. `o` names `plugin.explorer.toggle_dir`, which runs `open_entry(..., :toggle)`: on a directory `Tree#toggle`, on a file `open_path` with the same editing-window target as `:edit`. `h` names `plugin.explorer.collapse`, which collapses an expanded directory or moves to the parent row.

After a directory changes, `refresh` replaces the scratch buffer's lines inside a transaction that keeps the current window's cursor. A directory's children are listed after it, so expanding or collapsing it never moves its own line, at any depth.

## Goals / Non-Goals

**Goals:**
- `<CR>` toggles a directory and opens a file; `l`, `h`, and `o` keep their behavior.

**Non-Goals:**
- No new action, no new host request, no API version change.
- No configurable tree keymap.

## Decisions

- Bind `<CR>` to the existing `plugin.explorer.toggle_dir` instead of adding an action or a mode argument to `open`. `toggle_dir` already toggles a directory, does nothing on the root, and opens a file in the editing window exactly as `open` does (`open_path` treats every `how` but `:split`, `:vsplit`, and `:tab` as the editing window). Alternative: a new `plugin.explorer.activate` action with its own row and manifest entry; rejected as a second name for what `o` does. nvim-tree also gives `<CR>` and `o` the same action.
- Keep `l` on `plugin.explorer.open`, which expands and never collapses, as the brief asks and as nvim-tree's `l` (open, never close) behaves.
- No cursor code: the line of a directory does not move when it is toggled (Context), so the cursor rows asserted by the tests come from the existing `refresh` path. The Ctrl-W case goes through the same `in_tree?` check, since the context window is the tree's.
- The `?` line keeps its length: `<CR>/o toggle  l open  h close` replaces `<CR>/l open  h close  o toggle`.
- Remove the uncalled `Tree#show_hidden?` (periodic quality at 5b128b5) rather than reading it in `visible`, since the tree reads its own field there and nothing outside asks for it.

## Risks / Trade-offs

- [A user used to `<CR>` leaving an open directory open now closes it] → that is the requested behavior; `l` keeps the old one.
