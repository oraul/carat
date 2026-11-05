## Context

`buffer-substitute` left the ex grammar keeping the range as text, `ExRange` resolving it per handler, `ExecuteEx` as the `CommandRunner`, and `SubstituteLines` compiling a pattern under one `SearchBudget` and editing through one splice inside the dispatcher's transaction around `cmdline.execute`. Vim's `:global` works in two passes: it marks the matching lines in the buffer's line store, where every line insert and delete moves the marks with the lines, then repeatedly takes the first marked line, clears its mark, and runs the command there (`ex_global`, `global_exe`). Carat stores no ex-level line marks; the only marks moved by edits are the sign layers, shifted in `Buffer#splice` through `LineSplice.shift_marks`.

## Goals / Non-Goals

**Goals:**

- `:g`, `:g!`, and `:v` with the ranges of `buffer-substitute`, running any ex command per marked line, with Vim's marking semantics through inserted and deleted lines.
- `:d` as the line-deleting command a global most often runs.
- One undo step, the search translation, and the work budget.

**Non-Goals:**

- `:m`, `:t`, `:normal`, `:p`; the delimiters `\/`, `\?`, `\&`; command chaining with `|`; Vim's summed report after a global; Ctrl-C.

## Decisions

### The marks live on the buffer and move in its one splice

`Domain::GlobalMarks`, a `Struct` held by a new `Buffer#global_marks` member, keeps one integer flag per line while a global runs (an empty array otherwise) and a scan start, `low`. `Buffer#splice` calls `global_marks.shift(a, removed, inserted)` next to `shift_signs`, which returns at once when no global runs and otherwise moves the flags through `LineSplice.shift_marks`, the one row-shift rule: a line kept by an edit keeps its mark, extra removed rows lose theirs, inserted rows get none. `take` returns the first marked row at or after `low` and clears it; `shift` lowers `low` to the edited row when the edit is above it, because only rows from there on can have changed. Rows below `low` are always unmarked, so the scan is linear over a global that deletes or inserts at the visited line.

Alternatives: replaying the open transaction's change records after each command was rejected, since an undo or a write run by the command closes the transaction and the records then go elsewhere; the splice sees every edit, history replays included. Keeping the rows in the use case and guessing shifts from line counts was rejected as wrong for an edit above the visited line.

### GlobalCommand runs the command through the CommandRunner

`UseCases::GlobalCommand` takes the runner (`ExecuteEx`, built before the table is filled, as the plugin host takes it), `LastSearch`, `LastSubstitute`, the registers, and the search history. `call(state, range, args, invert)` parses `GlobalArgs`, compiles the pattern with `VimPattern.compile` under the case options, remembers it as `SubstituteLines#remember` does (Vim saves a global's pattern as both the search and the substitute pattern), marks the rows under one budget (`Search.searchable` and `Search.match_at` from column 0, `E363` with nothing run when it stops), then opens a transaction when none is open, loops `take`, moves the cursor to the row at column 0, and runs the command. The loop stops at the first failing outcome, or when `state.buffer` is no longer the buffer it marked. The marks are cleared after the loop in every case, so a later splice pays nothing. The handler `GlobalCommandHandler` (`g[lobal]` with the bang as the invert flag, `v[global]` inverting and refusing a bang) resolves the range, `%` without one, and passes the rows.

### One reader of the delimited pattern

`Domain::DelimitedPattern.parse(text, name)` reads the delimiter and the pattern as Vim reads them for `:s`, `:g`, and `:v`: the letter, backslash, and non-ASCII refusals, then `VimPattern.pattern_end`, returning the pattern, the text after the closing delimiter, and the error. `GlobalArgs.parse` and `SubstituteArgs.parse` both call it, so the two commands cannot drift on the delimiter rules (`docs/architecture.md` section 5, shared logic lives once in the domain). A reader on `VimPattern` was rejected, since it returns several values, which need a value class of their own file, and `VimPattern` is the pattern translator.

### Recursion follows Vim

`GlobalCommand` keeps a busy flag while it runs its loop. A global called while busy marks nothing: with a range other than every line it answers `E147: Cannot do :global recursive with a range`, otherwise it runs its command on the cursor line when that line is marked by the pattern, silently when not. The marks are the outer global's, so the inner one never touches them.

### :d is its own use case

`UseCases::DeleteLines#call(state, first, last, register)` extracts the rows as a linewise register entry, deletes them with `Buffer#set_lines`, writes `Registers#delete` with the numbered shift, and puts the cursor on the first non-blank of the row that took the first deleted row's place. `DeleteCommandHandler` (`d[elete]`) resolves the range and parses `[x] [count]` through `Domain::RegisterCount`, which a later `:y` or `:pu` can share; a count moves the range to count lines from its last line as `:s` does. It registers after the global handlers, in the order of `docs/compatibility.md`; no core command shares `d`, `g`, or `v` as a prefix (`:di[splay]` needs two letters, `:vs[plit]` and `:vne[w]` too).

### Messages

The listing of a global with no command is the marked lines joined by line breaks, which the message row already shows as a listing, the cursor on the first non-blank of the last one. With a command, the outcome is the last non-empty message a command gave, or the first failure.

## Risks / Trade-offs

- [A command that closes the transaction (`:undo`, `:w` is fine) splits the global into more than one undo step] → the global commits only a transaction it opened; recorded as a difference in `docs/compatibility.md`.
- [A command switching buffers stops the global where Vim goes on] → reported in the compatibility differences.
- [`Buffer` grows one member] → no allocation per key: the shift returns before touching anything when no global runs; `lh`, `j`, `insert`, and `undo` are checked with `make bench-budget` and `make metrics`.
- [A global over many lines builds a listing as large as the matched lines] → the same bound as the buffer itself; the message row shows the last lines of a tall listing.
