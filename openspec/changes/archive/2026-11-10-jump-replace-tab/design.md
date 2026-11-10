# Design

## Context

A buffer tab is a listed, non-scratch buffer of `BufferList#buffers`, painted in list order by `TabBar#paint`. `BufferList#load` shows a buffer in the current window, appending it to the list when new, and lets go of the old one through `release`, which keeps a file buffer listed (hidden). Jumps go through `VisitTarget#jump` (`gd` and a pick-list choice: `OpenFile` for a project file, `view` for an outside one) and `WalkJumps#call` (`Ctrl-O`, `Ctrl-I`, `BufferList#load`). The jump list is one per editor and stores buffer ids, found back with `BufferList#with_id`.

**Goals:** a jump to a buffer with no tab never grows the tab row; back and forth keeps its length; Vim's behavior one option line away; `:ls` and `:ls!` as Neovim's for an unlisted buffer.

**Non-Goals:** a jump list per window, other jump commands, `Ctrl-^` (Part 2); `gt` over buffer tabs (Part 3); `:set jumptab`.

## Decisions

- **Unlisted is a flag, not a removal.** `Buffer#listed` (true by default, Neovim's `'buflisted'`) marks a buffer a jump left. It stays in `buffers`, so its id, jump list entries (`with_id`), cursor, undo history, language server sync (the gateway walks the array), `:wa`, and the path rename and delete still find it. `Buffer#tabless?` (scratch or unlisted) replaces `scratch?` where the question is "has a tab": `TabBar` (paint, widths, overflow counts), `BufferList#step_from`, `file_count` (so `tab_row?`), and `replacement_for`. Removing the buffer from the list instead would drop it from the jump list (`WalkJumps` drops an entry whose buffer is gone) and give it a new number on return, against Neovim.
- **Relisting.** `BufferList#add` sets `listed` on a buffer already in the array, so every open (`:e`, `:b N`, the finder, the explorer, a jump) lists it again at its place in the array, as Neovim lists it again under its number.
- **The tab rule is one domain method, run after the jump.** `BufferList#hand_tab(left, target)` runs once the jump has shown `target`: it returns when `left` is `target`, already has no tab, is modified, or is still shown by a window (`TabList#shown?`), or when either is not in the list (an empty startup buffer the target reused). Otherwise it moves `target` to `left`'s index and unlists `left`. Since `left` then has no tab, the target is drawn where `left` was. The callers decide whether the target had a tab before the jump, since `load` lists it: `VisitTarget` asks the buffer of the target's file (`listed_for`, which finds unlisted buffers too), `WalkJumps` the entry's buffer, and both call `hand_tab` only under `option.jumptab replace` and when the target had no tab. A target that had a tab is selected and nothing else changes.
- **Back and forth.** After `gd` from A to B the array is `[B, A(unlisted)]`; `Ctrl-O` loads A (relisting it), then `hand_tab(B, A)` moves A to B's index and unlists B: `[A, B(unlisted)]`. The visible row keeps its length and position.
- **The option.** `Options#jumptab`, a string with the values `JUMPTABS = ["replace", "keep"]`, checked like `breadcrumbs`. `Options.new` keeps `keep` (Vim), the shipped configuration sets `replace`. The use cases read it from `state.options`, so no constructor changes and the assembly is untouched.
- **The listing.** `ListBuffers` treats an unlisted buffer as it treats a scratch one: hidden without the bang, flagged `u`, kept by the `u` filter.

## Risks / Trade-offs

- [A plugin's view of the buffers, the finder's buffer source if any, still sees an unlisted buffer] → the plugin API passes buffers by id and no request lists them by tab today; a later change can filter them.
- [Ctrl-O to an unlisted buffer whose tab-holder is modified] → already refused with E37 before any tab changes.
- [Default differs from Neovim] → recorded in the `gd`, `<C-o>`, and `option.jumptab` rows; `option.jumptab keep` restores it.

## Migration Plan

None: one shipped option line; a user who wants Vim's behavior adds `option.jumptab keep`.
