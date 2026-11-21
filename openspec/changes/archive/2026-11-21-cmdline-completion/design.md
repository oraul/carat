# Design

## Context

The command line has a cursor since #281 (`EditorState#cmdline_position`). Ex commands are `ExHandler`s in `ExTable`, registered in the precedence of `docs/compatibility.md`; `ExTable#find` resolves a typed name, `full_names` lists them in order. The file port's `list` reads every entry of a directory. Floats are drawn by `FramePresenter#paint_floats`; a float is a menu, filled with `Pmenu`, when its `selected` row is not negative.

## Decisions

- One record, `Domain::CmdlineMenu`, holds the matches, the selection (-1 for the typed text), the column the completed word starts at, the typed word, the line and cursor the last insert left, and the float. `current?(state)` says whether the command line is still in command-line mode with that line and cursor; `HandleKey#follow` closes the menu through `CloseCmdlineMenu` when it shows and is not current, one comparison per key otherwise, so every key that edits the line closes it without each handler knowing.
- `CompleteCommandLine#call(state, step)` does the rest: when the menu is current it moves the selection by step, wrapping through the typed text as Neovim's wildmenu does; otherwise it reads the text before the cursor, collects the matches, and selects the first (or the last for `<S-Tab>`). It replaces the word before the cursor with the selection, keeps the text after the cursor, and opens the float again.
- Command names: the text before the cursor is letters only, matched as a prefix of each full name of `ExTable#full_names`, in registration order. Paths: the text before the cursor is a name, an optional `!`, blanks, and the argument; `ExTable#find` resolves the name and its handler's full name must be one of `edit`, `write`, `split`, `vsplit`, `tabedit`. The argument is split at its last `/`: the directory part is listed relative to `FilePort#cwd`, as given when it starts with `/`, under `FilePort#home` when it starts with `~/`; the rest is a prefix of each entry's name. A `../` is listed as typed, so a path leaves the working directory only when typed so.
- The bound is a port request, `list_first(dir, limit)`, rather than a parameter of `list`, which four callers use with every entry; `DiskFiles` reads with `Dir#read` and stops at the limit, so a directory of a million entries costs 1000 reads, sorted after. The stat that marks a directory is made for the matching entries only.
- The popup is an editor-anchored float placed at the bottom of the area above the command line (a row past the screen moves up to fit), at the column of the word, bordered as `docs/design.md` frames a float, `selected` set past the last row while the typed text shows so the rows keep `Pmenu`; the matched prefix carries `PmenuMatch` style tokens.
- `<Esc>`: `NormalModeHandler` closes a showing menu and stays on the line; `CancelCommandLine` is left as it was, so `<BS>` on an empty line still leaves.
- `<S-Tab>` is a new key code; an unbound one is left unbound (no fallback to `<Tab>`), so no other mode changes.

## Risks

- A directory with more than 1000 entries completes from the first 1000 the system returns, not the first 1000 by name; the compatibility row says so.
- The float's row and column come from the screen size at `<Tab>`; a resize while it shows leaves `FloatWindow#place` to fit it.
