# Design

## Context

At be4b63a one `Domain::JumpList` is built in `EditorAssembly` (`@jumps`, line 348) and handed to `VisitTarget` and `WalkJumps`; the only `push` outside the record is `VisitTarget#jump` (`gd`). Every other buffer switch goes through `BufferList#load` (`SwitchBuffer` for `:b`, `:bn`, `:bp`, `:bN`, and the buffer keys; `OpenFile` for `:e`, the finder, the explorer, `:sp file`, `:tabedit file`, and `gd`'s project targets), which remembers the cursor on the buffer left but records no jump. A new window is made by `Layout#split` (`Window#copy_from`) and by `OpenTab` (`Window.new`). `BufferList#hand_tab` (the `option.jumptab replace` rule) has no guard for a scratch target, so `WalkJumps` back to a scratch buffer still shown elsewhere unlists the file left (#98). `JumpList#step` pushes the start position before its bounds check, so Ctrl-O on an empty list leaves an entry.

## Goals / Non-Goals

Goals: one list per window, copied by a new window; every buffer switch records the position left; the tab rule reached through the window's list; #98's scratch guard; the `step` bounds check; `:bfirst` and `:blast`.

Non-goals: the alternate file and the jump motions (`jump-motions`), `:jumps`, the tab keys (`tab-keys`).

## Decisions

### The list is a member of the window

`Window` gains a `jumps` member (`JumpList`), built empty in `initialize`. `Window#copy_from` copies it with `restore_from` (the arrays are duplicated, so the two lists change apart), so `Layout#split` gives the new window its parent's list, as Neovim's `win_init` does; `OpenTab` copies the current window's list into the new tab page's window the same way. `VisitTarget` and `WalkJumps` lose their `jumps:` keyword and read `state.window.jumps`; the `EditorAssembly#jumps` reader and its row in `test/adapters_assembly.rb` go away, since nothing is shared any more. Alternative: a table of lists by window id in the assembly; rejected, as a closed window would leave its list behind and the split would need to know the table.

`domain/jump_list.rb` moves before `domain/window.rb` in `carat.rb`, and `window.rb` requires it.

### One recording switch beside `load`

`BufferList#enter(target)` records the current window's cursor in its list, then calls `load`. It records nothing when the window already shows `target`, when the buffer left has no id, or when `target` is new and the buffer left is the reusable empty startup buffer (which leaves the list and gives its number to `target`, so the entry would point at the file itself). `OpenFile` (both of its `load` calls) and `SwitchBuffer` call `enter`; `load` stays the primitive for the walk (Ctrl-O must not record), `:bd`'s replacement, `bring`, and the side windows. `OpenFile`'s reload of the current buffer's own path is no switch and records nothing.

`gd` keeps its own `push` after the move, so a target in the same file records; for another file, `OpenFile` already recorded the same buffer and row, and the duplicate rule keeps one entry. `VisitTarget#view` (outside targets) calls `enter` too, for the same single entry.

### The walk and the tab rule

`WalkJumps` reads the window's list and keeps its `@saved` copy for the E37 refusal. The tab rule's condition, written twice as `!tabbed && jumptab == REPLACE`, becomes `Options#jump_takes_tab?` (true under `replace`), with `!tabbed` read beside it. `hand_tab` returns early when `target.scratch?` (#98): a scratch buffer never has a tab to take or give.

### `step` checks before it records

Going older from the newest end, `step` first works out the length the push would leave (one more, less an entry on the same buffer and row, at most `LIMIT`); when `length - 1 + by` is below 0 it answers -1 and records nothing. The rest is unchanged.

### `:bfirst` and `:blast`

`BufferRequest` takes the targets `:first` and `:last`; `SwitchBuffer` finds them with `BufferList#first_file` and `#last_file` (the first and last buffer without `tabless?`), E85 when none. `BufferCommandHandler` registers `bf[irst]`, `br[ewind]`, and `bl[ast]` after `bN[ext]`, with no argument (E488 for one, as `:bn` with a word); none shares an abbreviation with an earlier command (`:b`, `:bn`, `:bp`, `:bN`, `:bd` are full matches only of their own spellings).

## Risks / Trade-offs

- [A `JumpList` per window costs three small arrays per window] → windows are few and made on a key, never per render; the allocation budgets read keys that make no window.
- [`OpenFile` now records for `:sp file` and `:tabedit file`] → Neovim records there too (the new window's list holds the position left); a row checks the split.
- [`gd` records twice for another file] → the second push is the same entry, dropped by the duplicate rule; a row checks one entry.

## Migration Plan

None: no configuration or file format changes.

## Open Questions

None.
