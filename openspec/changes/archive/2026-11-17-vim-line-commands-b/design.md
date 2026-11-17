# Design

## Context

`ExGrammar` reads a command name as a run of letters or one `&`, so `:>` and `:<` never reach a handler. The line commands `:d`, `:m`, `:co`, and `:t` are separate `ExHandler` subclasses, each refusing a bang, resolving the range, and (for `:m` and `:co`) reading the target and placing the cursor with a copied method. `Domain::Operators.join` (behind `J`) and `Domain::Operators.shift` (behind `>>`) already do the text work Neovim's `do_join` and `op_shift` do. `ExRange.target` returns the line the lines go below, numerically the row they are put at, and decides between E16 and Not implemented by its own test, while `resolve` answers Not implemented for every piece it cannot read.

## Goals / Non-Goals

**Goals:**
- `:j`, `:j!`, `:{range}j`, `:j {count}`, `:>`, `:>>`, `:<`, with ranges and counts, as Neovim's `ex_join` and `ex_operators` do.
- One prelude, one `REPORT`, one E477, one address classification.

**Non-Goals:**
- Flags after the commands, `'shiftround'`, `'joinspaces'`, and the `#` rule of `'smartindent'`.
- Any change to what `:m`, `:co`, `:t`, or `:d` do or answer.

## Decisions

- A base class `UseCases::LineCommandHandler < ExHandler` (`use_cases/ex/line_command_handler.rb`), a handler base as `ExHandler` is, so it keeps the handler shape rather than a use case's: `ranged?` true, `bang?` false (overridden by `:j`), and private helpers `lines_of(state, command)` (E477 for a bang the command does not take, then `ExRange.resolve`), `target_of(state, command)` (`ExRange.target` on the argument), and `place_cursor(state, row)` (the wanted column, clamped). `:d`, `:m`, `:co`, `:t`, `:j`, `:>`, `:<` derive from it. Alternative: a concern; rejected because the prelude is shared by exactly one family of handlers with one base already in place (`ExHandler`), and a concern's methods carry no signatures.
- `ExRange#counted(count, line_count)`: Neovim's count after a line command, the range's last line and count - 1 more, stopping at the last line; `:d`, `:j`, `:>`, `:<` use it. Logic shared by several handlers goes to the domain (architecture section 5).
- `RegisterCount.parse_count(text)` reads a count with no register, refusing a leading non-digit as trailing characters (E488), so `:j a` and `:> x` refuse what Neovim refuses.
- `Domain::Messages::E477` and `Domain::Messages::REPORT` hold the message and Neovim's `'report'`, the domain's place for a constant several use cases and handlers need.
- `ExRange.line_of(text, row, line_count, selection)` is the one reading of a single address: the line it names, E20 for an unset visual mark, E16 past the last line or for text that is not an address, and a Not implemented refusal for an address Carat does not read (an offset `+`/`-`, `;`, a pattern, another mark, a `%` that is not the whole range, or numbers joined by blanks, which Neovim adds). `resolve` keeps its message, `Not implemented: range` with the whole range as the command-line-mode spec requires, and `target` its `Not implemented: address`; both decide which error by the same rule. `target` answers the row the lines are put at (0 above the first line), which is the 1-based line they go below, so `:m` compares rows with rows and no handler converts between bases.
- `:j` counts the addresses typed as Neovim's `addr_count` does (none, one, or two for `%` or a comma, one more for a count): one line given with two addresses changes nothing, the cursor line being the last changes nothing, and otherwise one line joins the next. The cursor goes to the first line of the range, on the first non-blank of the joined line (`beginline(BL_WHITE | BL_FIX)`); no message, as `do_join` gives none.
- `:>` and `:<` read the run of their own character after the name as the amount (`:>>` is two), then the count; the cursor goes to the last line's first non-blank (`op_shift` leaves it after the indent of the last line); above `REPORT` lines the message is Neovim's "N lines >ed M time" or "... times".
- `ExGrammar` reads `>` and `<` as one-character names, the rest of the run staying in the argument, so `:>>` is the name `>` with the argument `>`, as Neovim reads it.

## Risks / Trade-offs

- [`target` of digits joined by blanks now answers Not implemented where it answered E16] → Neovim adds such numbers, so E16 was the wrong answer; `domain_ex_range` pins the new one.
- [`resolve` of text that is not an address answers E16] → the grammar never hands `resolve` such text from the command line; the domain test pins it.
