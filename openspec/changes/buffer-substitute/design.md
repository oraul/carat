## Context

`ExGrammar.parse` reads `:`, a run of letters as the name, a bang, and the rest as the argument; `ExCommand` has no range and `ExecuteEx` answers E492 for anything that does not start with a letter. Search (`buffer-search`) translates Vim patterns with `VimPattern` into constructs Spinel's engine runs without backtracking, with non-capturing groups, and charges every scan to a `SearchBudget` through `Search.match_at`. The dispatcher opens one transaction around every action, `cmdline.execute` included, so every buffer edit an ex command makes is one undo state. The window keeps its last visual selection for `gv`.

## Goals / Non-Goals

**Goals:**

- Ranges parsed once in the grammar and resolved by one domain function, so `buffer-global` reuses them.
- One substitute use case behind `:s`, `:&`, `&`, and `g&`, with Vim's flag, memory, and message rules.
- No pattern or replacement can crash or hang the editor or grow memory without bound.

**Non-Goals:**

- `:g`, `:v`, the confirm flag, `\=`, and addresses with arithmetic or patterns (proposal, Out of scope).

## Decisions

### The grammar keeps the range as text; `ExRange` resolves it

`ExCommand` gains `range`, the range as typed (`""` for none). `ExGrammar.parse` reads it before the name: digits, `.`, `$`, `%`, `,`, `;`, `+`, `-`, blanks, and `'` with the character after it. `ExRange.resolve(text, row, line_count, selection)` turns it into a value with `first` and `last` rows, whether a range was given, and an error; an unsupported address gives `Not implemented: range x`. Reading the arithmetic characters in the grammar, though they are not resolved yet, makes `:.+1s/a/b/` report Not implemented instead of a misleading E492, and leaves `buffer-global` or a later change only the resolver to extend. Alternative: a list of address records in `ExCommand`; it would put rows that depend on the cursor into a value parsed before the command runs, and Spinel types arrays of records poorly.

`'<` and `'>` are the top and bottom rows of `Window#last_selection`, clamped to the buffer, since the selection is not moved by later edits (Vim's marks are). A backwards range is refused with E493: Vim asks to swap, and Carat has no confirmation prompt.

### `ExecuteEx` owns the range checks every command shares

`ExHandler#ranged?` is false by default and true for the substitute handler; `ExecuteEx` answers E481 when a range comes with a command that takes none, and moves the cursor for a range with no command, as `G` does (Neovim's `nostartofline`). Each ranged handler resolves the range itself through `ExRange`, because the default without a range differs per command.

### The `&` name

`:&` is one character that is not a letter. The grammar reads a name of one `&` when the text starts with it, so `:&&` is `&` with the argument `&` (the keep-flags flag), as Vim parses it.

### Substitute pieces in the domain

- `SubstituteArgs.parse(text, allow_pattern)`: the delimiter, pattern, raw string, flags, and count, or the error (`E146`, `E488`, `E939`, Not implemented for `\` as delimiter). `:&` passes false, so its argument is flags only.
- `LastSubstitute`: Vim's static memory: the last substitute pattern, the raw string `:&` reuses, the expanded string `~` inserts, and the persistent flags (`g`, `e`, `n`, case, print).
- `Replacement`: `tilde` expands `~` as Vim's `regtilde` does; `check` refuses `\=` and `\n` before anything changes; `expand` builds the text for one match. A line break is written as `"\n"`, which no buffer line holds, so a carriage return in the matched text stays a character.
- `Substitution.line(pattern, line, string, all, count_only, budget)`: one line's result, found with `Search.match_at` on `Search.searchable(line)` and cut from the original line by code point, so illegal bytes are kept; the empty-match rule is Vim's `do_sub` (`matchcol == prev_matchcol`).
- `VimPattern.compile_substitute(source, ignorecase, smartcase, previous, has_previous)`: the same translation with `\(` capturing (at most nine, `E51` beyond, as Vim) and `~` as the previous string in a non-capturing group. Search keeps non-capturing groups and its E33 for `~`, since threading the substitute memory into the four search call sites is outside this change.

### One budget per command, and nothing changes when it runs out

`SubstituteLines` resets its own `SearchBudget` to `SEARCH` per command. Besides each scan, every character of replacement text is charged `OUTPUT_COST` units, so a command produces at most `SEARCH / OUTPUT_COST` characters of new text (25 million at a cost of 16), which bounds memory as well as time; a long line already pays its length on every scan, which bounds the matches. The new lines are built first and applied only when the whole range finished, so an exhausted budget leaves the buffer as it was with E363.

### One splice for the changed span

The changed lines, from the first to the last changed row, replace that span in one `Buffer#set_lines`, unchanged lines inside it shared. Splitting lines with `\r` on many rows would otherwise move the line array's tail once per row (quadratic); the cost is that sign marks inside the span keep their row index when lines are split. It is one undo state either way, inside the dispatcher's transaction.

### `&` and `g&` are actions, not key replays

`SubstituteHandler` (`substitute.repeat`, `substitute.repeat_all`, kind `:action`, `repeat: false`) calls `SubstituteLines` with `SubstituteArgs.parse("", false)` on the cursor line and count lines, or with `//~/&` on every line, which is what Vim's `&` and `g&` expand to. Neither is a dot change in Vim, so neither is here.

### `:` in a visual mode

`EnterCommandLine` ends a visual mode through `EditorState#end_visual` and starts the line with `'<,'>`; the visual maps bind `:` to `mode.cmdline`, so no new action is needed.

## Risks / Trade-offs

- [The budget caps a `:%s` over a very large file] → the charge is the one search already uses per scan; a 100,000-line file of short lines costs a few percent of it. An exhausted budget is reported and changes nothing.
- [Sign marks inside a span that `\r` split stay on their row index] → recorded here; signs are recomputed by their plugins on the change notice.
- [`~` in a `/` pattern still answers E33 after a substitute] → recorded in `docs/backlog.md` with the fix outline.
