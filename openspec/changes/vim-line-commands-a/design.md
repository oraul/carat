## Context

The ex table tries handlers in registration order (`ExTable`), `ExecuteEx` runs the command line inside the dispatcher's transaction (so `:d` through `DeleteLines` is one undo step), and `GlobalCommand` runs each marked line's command through the same runner inside its own transaction, with `GlobalMarks` shifted by every `Buffer` splice. `ExRange.address` already reads one address (`.`, `$`, a number, `'<`, `'>`), `-1` for text it does not read and `-2` for an unset mark.

## Goals / Non-Goals

**Goals:** `:m`, `:co`, and `:t` with Neovim's results for a range and a target, `E134`, `E16`, one undo step each, and the right lines under `:g`.

**Non-Goals:** address offsets and patterns as targets, flags after the address, the move-command fold handling, `:normal` and `:p`.

## Decisions

- The target: `ExRange.target(text, row, line_count, selection)` returns an `ExRange` whose `first` and `last` are the target line number (0 for above the first line), or its refusal: empty text, a number past the last line, or text `address` cannot read is `E16`; text holding `+`, `-`, `;`, or starting with `/`, `?`, or `'` (but `'<` and `'>`) answers `Not implemented: address x`, as `resolve` answers ranges; an unset `'<` is `E20`. Reusing the `ExRange` value keeps one result type and the existing refusal constants. Alternative: a new `ExTarget` value, rejected as a second type for one integer and an error.
- The edits: the handlers edit directly through `Buffer#set_lines`, no use case, since neither has a collaborator (no register, no port) and both are a few lines: a move takes `lines_of(first, last)`, deletes the rows, then inserts them at the target minus the moved count when the target is below the range; a copy inserts a copy at the target. Two splices, not one over the union, so `GlobalMarks` of the lines between the range and the target shift and the marks of other lines stay. Both run inside the transaction the caller opened (the command line or the global), so each is one undo step.
- Neovim's `do_move`: a target inside the range (line1 <= target < line2) is `E134: Cannot move a range of lines into itself`, today's Neovim wording; a target of line1 - 1 or line2 changes nothing and only moves the cursor as a move would.
- The cursor: the last moved or copied line, its column the wanted column clamped to that line in normal mode (`Domain::Motions.wanted_col` reads the mode, so the handler clamps with the normal-mode bound itself), keeping `want_col`, as Neovim's `beginline(BL_SOL | BL_FIX)` under `nostartofline` does.
- The messages: `N lines moved` and `N more lines` above Carat's fixed `'report'` of 2, as Neovim gives them.
- One handler class per command, `CopyCommandHandler` registered twice, under `co[py]` and `t`, as `GlobalCommandHandler` is registered under two names.
- Registration: after `MessagesCommandHandler`, before the plugin commands, rows after `:mes[sages]` in `docs/compatibility.md`; `m`, `co`, and `t` are no other core command's abbreviation, so the place changes no lookup.

## Risks / Trade-offs

- [`:m+1` and `:t-` are common in Neovim and answer Not implemented] → recorded in `docs/compatibility.md`; offsets come with the range offsets.
- [Text after the address gives `E16` where Neovim may give `E488`] → recorded as a difference.
