# Design

## Context

Each of the four bugs is a path that does part of what its sibling does. `InsertTab` measures by code point while `DisplayWidth.column` (used by the presenter, the block operators, and `>` with a tab) measures by screen cell. `Keymap#bind_owned` creates nodes as it walks for every value, while `remove_owner` prunes what it empties. `Buffer#revert_to` applies the inverse of each record without the `global_marks.shift` that `splice` makes. `HandleKey#timeout` repeats the end of `HandleKey#call` but keeps only two of its follow-ups.

## Goals / Non-Goals

Goals: each path does what its sibling does, with a row that fails before and passes after; allocations and rounds stay main's. Non-goals: new options, the key hints float, or any change to the trie's layout.

## Decisions

### Tab pads from the display column

`InsertTab#call` computes `DisplayWidth.column(buffer.line(row), col, width)` and pads `width - dcol % width` spaces. It passes the same `width` it pads by (tabstop, or 8 when tabstop is 0 or less), so a tab before the cursor spans the cells the pad assumes. The column walk is linear in the cursor column, once per Tab, with no allocation beyond the line read the buffer already holds.

### A none line prunes what it empties

`bind_owned` with a nil value goes to a private `unbind(mode, codes)`: it walks with `child?`, returning at the first missing child (nothing was bound, so nothing is created), clears the end node's value and owner, then walks from the deepest node up, deleting each child left with neither a value nor children, and stops at the first node that still holds either. Walking the path twice from the root keeps the method free of a node array. A binding with a value keeps the creating walk.

### revert_to moves the marks back

`revert_to` calls `global_marks.shift(change.row, gone, change.removed.length)` beside `shift_signs`, the same arguments the signs get: the inverse splice removes the record's inserted rows and puts back its removed ones. `shift` returns at once when no global runs, so the undo path outside `:g` pays one check. A row inserted by the reverted edit had no mark, and a marked row the edit deleted comes back without its mark, as a deleted marked row stays unvisited.

### One follow tail for call and timeout

The follow-ups at the end of `call` (completion, hover, definition, signature, palette, prompt, observe, arrange) move into one private method, `follow(state)`, which both `call` and `timeout` end with. `timeout` keeps not hiding the key hints, which the brief does not name. Every check stays the one comparison it was, so a key with no float open does the same work as before.

## Risks / Trade-offs

- A configuration that relied on a `none` line making a prefix wait loses that wait; it was the bug.
- The pad now depends on the line before the cursor; a line with control characters counts each as two cells, as the screen draws it.

## Migration Plan

None: no option, file, or binding changes.

## Open Questions

None.
