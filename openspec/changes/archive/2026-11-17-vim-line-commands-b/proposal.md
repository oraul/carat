# Proposal

## Why

`:j`, `:>`, and `:<` are Neovim line commands a user asked for and Carat refuses with E492. The line commands of sprint 14 also repeat themselves: `:m` and `:co` copy the bang, range, and target prelude and the cursor placement, `REPORT = 2` is private in three files, "E477: No ! allowed" is spelled in five handlers, and `ExRange.target` classifies an address it cannot read by its own rule and answers a 1-based line where `resolve` answers rows. The change is outside the numbered roadmap of `docs/architecture.md` section 12: it is Neovim compatibility work from the feature queue.

## What Changes

- Add `:[range]j[oin][!] [count]`: join the lines of the range, the cursor line and the next without one, a count joining count lines from the range's last line, with Neovim's spacing (none with `!`), the cursor on the first non-blank of the joined line, one undo step; one line with two addresses, or the last line, changes nothing.
- Add `:[range]> [count]` and `:[range]< [count]`, each repeated character shifting once more (`:>>`): shift the lines of the range, the cursor line without one, by `shiftwidth`, the cursor on the first non-blank of the last line, "N lines >ed M time(s)" above two lines, one undo step; a bang is E477.
- Let `ExGrammar` read `>` and `<` as a one-character command name, as it reads `&`.
- Add a `LineCommandHandler` base for the line commands (`:d`, `:m`, `:co`, `:t`, `:j`, `:>`, `:<`) holding the bang and range prelude, the target, the count, and the cursor placement once.
- Move "E477: No ! allowed" and Neovim's `'report'` into `Domain::Messages` (`E477`, `REPORT`), used by every handler and use case that spelled them.
- Classify an address `ExRange` cannot read in one place for `resolve` and `target`, and make `target` answer the row the lines are put at, the base `resolve` uses; `:m` compares rows only.
- Name the line commands in map area 12, and add the compatibility rows.

Out of scope: the flags of `:j`, `:>`, and `:<` (`l`, `p`, `#`), which answer E488 as trailing characters; `'shiftround'`; offsets, patterns, and other marks in addresses; `:m` and `:t` behavior, which stays as it is.

## Capabilities

### New Capabilities

### Modified Capabilities
- `line-commands`: adds the requirements of `:j`, `:>`, and `:<` and their refusals.

## Impact

- Code: `carat/domain/ex_grammar.rb`, `carat/domain/ex_range.rb`, `carat/domain/messages.rb`, `carat/domain/register_count.rb`, a new `carat/use_cases/ex/line_command_handler.rb`, new `join_command_handler.rb` and `shift_command_handler.rb`, the move, copy, delete, substitute, and global command handlers, `carat/use_cases/search/substitute_lines.rb`, and `carat/adapters/editor_assembly.rb`.
- Tests: `test/editor_line_commands.rb`, `test/domain_ex_range.rb`, `test/domain_ex_grammar.rb`, `test/use_cases_ex.rb`.
- Docs: `docs/compatibility.md` (rows for `:j`, `:>`, `:<`, the ranged commands), `docs/codebase-map.md` area 12, `docs/architecture.md` section 5.2 (the editing ex commands).
- README.md: changed, the line commands list names `:j`, `:>`, and `:<`.
- docs/architecture.md: changed, section 5.2 names `j > <` among the editing ex commands.
