# Design

## Context

`BufferList` (`carat/domain/buffer_list.rb`) is the list: membership in `buffers` is being listed, `id` is the stable number from `next_id`, and the keep policy lives in `release` and `load`, which today drop a clean buffer as soon as no window shows it. `BufferList#load` is the one place a window switches to another buffer (`OpenFile`, `SplitWindow`, `Quit`), `close_window` and `close_tab` the places windows close. `Window#show` resets the cursor. `QuitAll` and `Quit` answer the plain `E37`. Ex commands are `ExHandler`s registered in the order of `docs/compatibility.md`; a multi-line message is a message with `"\n"`, as `:registers` shows.

## Goals / Non-Goals

**Goals:** Neovim's buffer numbers, flags, and switch rules for the five commands, `E162` wherever Neovim's `check_changed_any` gives it (`:qa`, and `:q`, `:q!`, `:wq`, `:x` on the last window), and one keep policy that every path shares.

**Non-Goals:** an unlisted-but-kept state (Neovim's `:bd` keeps the buffer unlisted; here it is gone, its number never reused), re-reading a hidden buffer's file, the alternate buffer and the jump list.

## Decisions

### The keep policy moves into two lines of `BufferList`

`release(target)` removes only a scratch buffer no window shows; `load(target)` calls `release(old)` instead of removing it. Every caller (`CloseWindow`, `CloseOtherWindows`, `close_tab`, `SaveAll`, the plugin host) then keeps file buffers without a change of its own. `SaveAll`'s release loop goes, since it could only drop scratch buffers, which it never writes. Alternative: a `listed` flag on `Buffer` with unlisted buffers kept in the array, as Neovim does; rejected because every walk of the list (`for_path`, `with_id`, `modified_buffer`, `SaveAll`, `RenamePath`, `DeletePath`, the plugin host) would have to skip them, for the one feature (`:ls!` of deleted buffers) that is out of scope.

### Reusing the empty startup buffer

`load(target)` with a target never listed (`id == 0`) over an old buffer that is unnamed, not scratch, unmodified, one empty line, and shown by no other window removes the old buffer first and gives the target its id, then lists and shows the target, so the feed reads `close 1` then `open 1 a.txt`, never an open followed by a close of the same id. This is Neovim's `BLN_CURBUF` reuse; without it the file given at startup would be buffer 2 behind a hidden `[No Name]` that `:bn` would visit.

### The remembered cursor is a `Buffer` member

`Buffer#last_cursor`, a `Position`, set by `load` from the window's cursor before it shows another buffer and by `close_window` (which `CloseWindow`, `CloseOtherWindows`, and `Quit` go through) and `close_tab` before a window goes; `load` puts the cursor of the window back at the target's `last_cursor`, clamped to the text, after `Window#show`. One position per buffer, where Neovim keeps one per window with a fallback to the most recent; the difference shows only when two windows left the same buffer at different places. `:ls` reads it for every buffer but the current one.

### Use cases under `carat/use_cases/buffers/`

`ListBuffers#call(state, flags, bang)` builds the listing; `SwitchBuffer#call(state, request)` takes a `BufferRequest` (`target` `:next`, `:previous`, `:number`, or `:current`, `count`, `bang`), as `SwitchTab` takes a `TabRequest`; `DeleteBuffer#call(state, number, bang, typed)`, `typed` being the command for `E516`. `BufferCommandHandler` parses the argument (digits, empty, or other) and registers `ls`, `buffers`, `files`, `bn[ext]`, `bN[ext]`, `bp[revious]`, `b[uffer]`, and `bd[elete]` after the tab page commands, none of which share an abbreviation with them. The cycle and the unsaved-buffer search are `BufferList` methods (`step_from`, `first_unsaved`), shared logic in the domain as section 5 asks; going to a buffer's window is `TabList#focus_buffer`.

### `:bd` follows Neovim's `do_buffer` order

Refuse a modified buffer (`E89`); when it is the current buffer and no other listed file buffer exists, close the other windows showing it and load a new empty buffer; otherwise close the current window while it shows the buffer and another window exists anywhere, then close every other window showing it, restarting the walk after each close since a tab page may go, and, when the last window still shows it, load the next listed file buffer, or the previous one. The buffer is removed last, so its `buffer_close` follows the window changes. The next buffer is the list neighbour, where Neovim first tries the most recently visited one from the jump list, which does not exist here.

### `E162` and going to the buffer

`BufferList#first_unsaved(hidden_only)` walks the current buffer, the current tab page's windows, the other tab pages', then the list, as `check_changed_any` does, skipping scratch buffers. `BufferList#bring(target)` focuses the first window showing it through `TabList#focus_buffer`, or loads it in the current window. `Messages.unsaved_buffer(name)` is the two lines. `QuitAll` uses `first_unsaved(false)`; `Quit` keeps its one-line `E37` for a modified current buffer and uses `first_unsaved(true)` for `:q`, `:q!`, and `:written`. `:q!` removes the current buffer when it is modified and no window shows it after the switch, which discards its changes as Neovim's unload does and keeps two hidden modified buffers from trading places on every `:q!`.

### A modified current buffer refuses a switch

`:bn`, `:bp`, `:bN`, and `:b N` refuse a modified current file buffer with the `E37` of `:e` unless the bang is given, the rule `:e` already follows (Neovim with `'hidden'` off); with the bang the buffer stays hidden with its changes (`:buffer!`). A scratch buffer is never unsaved work and never refuses.

## Risks / Trade-offs

- [A clean hidden buffer shows its text as loaded, not the file's current text] → `:e!` in its window reloads it; `docs/compatibility.md` records the difference.
- [Plugins see `buffer_close` only on `:bd`, where they saw it when a window closed] → the API events are unchanged in kind; `docs/plugins.md` already says the event fires when a buffer leaves the list.
- [Memory grows with every file opened] → as in Neovim with `'hidden'` on; `:bd` frees it, and each file is capped at 64 MiB by `OpenFile`.
- [Restoring the cursor changes the snapshots of tests that bring a buffer back] → reviewed in the snapshot diff.
