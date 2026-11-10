# Design

## Context

`VisitTarget#jump` opens a definition target inside the working directory (links resolved by `ResolveInside`) through `OpenFile`, and any other target through `view`, which builds an unnamed buffer owned by `:definitions` and titled with the path: a scratch buffer. `Buffer#scratch?` (an owner set) means several things at once: never written (`SaveFile`, E382), never unsaved work, no tab (`TabBar#paint` skips it at both ends and selects no tab while it is current), unlisted as soon as no window shows it (`BufferList#release`), skipped by `:bn`, `:bp`, `:b N`, refused by `:bd` (E516), no indent guides, no signs. The archived `definitions` design chose the scratch view so a server could not steer the user into editing and saving a system file; it got the tab bar's and buffer commands' exclusions with it.

The reproduction (the new table in `test/adapters_definitions.rb`, run before the fix) reads, per case, the tab row, the selected tab, the current buffer, and the buffers listed:

- inside, `/project/b.rb`: ` r a.rb    r b.rb | b.rb | b.rb 1:4 | 2`, correct;
- outside, `/gems/c.rb`: `# c |  | /gems/c.rb 1:4 | 2`: no tab row (one file buffer), nothing selected;
- linked out, `/project/out.rb`: `# c |  | /project/out.rb 1:4 | 2`: the same;
- outside and already listed through `:e /gems/c.rb`: ` r a.rb    r c.rb |  | /gems/c.rb 1:4 | 3`: the file's tab shows but is not selected, the window shows a third, scratch copy, since `view` consults only `scratch_for` and never the listed file buffers. This is a ghost in the user's sense: a tab that cannot be focused.

## Goals / Non-Goals

**Goals:** the target of `gd` always has a tab that shows, is selected while current, and is reached and closed by the buffer commands; a target outside the project stays never written; a listed outside file is shown, not copied.

**Non-Goals:** `Ctrl-W gd`, an `[RO]` status marker, `:set readonly`, `:view`, refusing edits (`'modifiable'`), any change to the scratch concept or to the tab bar.

## Decisions

- **A read-only file buffer, not a tabbed scratch buffer.** `Buffer` gains a boolean `readonly` member (false by default, Neovim's option name, a record member named for its value as `test/lint.rb` asks). `view` builds `Buffer.from_text(text, PathPolicy.shown(cwd, path))`, so the buffer has a path (the absolute path outside the project, `out.rb` for a project file linked out), its file type and icon from the path, no owner, and `readonly = true`, then `@buffers.load` lists it. It is therefore a file buffer for the tab bar, `BufferList`, `:bn`, `:bp`, `:b N`, `:bd`, and `:ls`, with no change to any of them. The alternative, a predicate such as `tabbed?` for `:definitions` scratch buffers, would have to change the tab bar, `BufferList#release`, `file_count`, `SwitchBuffer`, `DeleteBuffer`, and `ListBuffers`, and would teach the domain a use case's owner name; the scratch concept stays as it is.
- **Never written, no override.** `SaveFile#call` refuses a read-only buffer first, with `E45: 'readonly' option is set`, before the path argument is looked at, so `:w`, `:w name`, `:wq`, `:x`, the save action, and through it `SaveAll` (`:wa`, `:wqa`, `:xa`, which go on to the other buffers after a failure, as Neovim's `do_wqall` reports E45) never write it. Every write of buffer text goes through `SaveFile` (`FilePort#write` has no other buffer caller), so this is the one guard. Neovim's `:w!` overrides `'readonly'`; Carat's `SaveFile` takes no bang and the refusal holds, which keeps the security property of the `definitions` design. Neovim's message ends with `(add ! to override)`; Carat leaves that hint out since no bang overrides it.
- **Edits behave as on a Neovim read-only buffer.** The buffer may be edited and is then modified: E37 guards `gd`, Ctrl-O, `:e`, and `:b` away from it, and E162 guards quitting, until `:e!`, a bang, or undo back to the saved state. The scratch view never counted as unsaved work; a read-only file buffer that did not would let a modified buffer be dropped silently, unlike Neovim.
- **The language server sees it.** The gateway syncs every listed buffer of its file type with a path, so the read-only buffer is opened with `didOpen` like a file the user opened with `:e`, as Neovim's client attaches to it; `gd`, `K`, and the diagnostics then work inside the gem's file. The text sent is the file the server itself pointed to.
- **A listed buffer first.** `view` first asks `listed_for(path)`, now the listed buffer whose normalized absolute path equals the target's, read-only or not, and shows it with `@buffers.load` (message `"path"`, with ` [readonly]` when it is), as `OpenFile` does for a listed buffer. A file the user opened writable with `:e /gems/c.rb` stays writable: `gd` shows the user's buffer, it does not make it read-only. The `:definitions` scratch-view clauses of `jump` and `listed_for` are removed, since no such view is made any more (the pick list and the peek float keep their `:definitions` scratch buffers, which are floats and never listed targets).
- **`:ls` shows the flag.** The fourth flag column, a space until now, reads `=` for a read-only buffer, and `=` leaves the filter characters that match nothing, as in Neovim's listing.

## Risks / Trade-offs

- [A server points outside the project to make the user edit and save a system file] → the buffer is read-only and `SaveFile` refuses it with no override, the same guarantee the scratch view gave. A read-only buffer keeps the flag through `:e` (the listed buffer is shown, not read again) and through renames.
- [Edits to the read-only buffer now block leaving it] → Neovim's behavior for a read-only buffer; `:e!`, undo, or a bang leave it, and the message is the usual E37.
- [The outside file now reaches the language server through didOpen] → the server named that file itself; the sync is the existing file-buffer path, with its caps.

## Migration Plan

None: no configuration, file, or protocol changes. A session never persists buffers.

## Open Questions

None.
