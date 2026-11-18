# Proposal

## Why

`:normal` and `:p` are the ex commands a `:g` most often runs besides `:s` and `:d`, and Carat answers both with E492, so `:g/x/normal Ax` and `:g/x/p` do not work. The sprint-16 review also found part b's range sentence garbled in `docs/compatibility.md`, a hand clamp in `LineCommandHandler#place_cursor` beside `EditorState#clamp_col`, `:j` re-reading the range text for its address count beside `ExRange.resolve`, and three methods missing from map area 12. The change is outside the numbered roadmap of `docs/architecture.md` section 12: it is Neovim compatibility work from the feature queue, part c of 3 of the line commands.

## What Changes

- Add `:[range]norm[al][!] {commands}`: run the characters of the argument, read literally, as keys typed in normal mode, once at the cursor without a range and once per line of a range with the cursor on column 0 of the line; an unfinished command is ended as if Esc were typed; the keys are one undo step with the command; E471 without an argument, E192 past 100 nested `:normal` commands.
- Add `:[range]p[rint] [count]`: show the lines of the range, the cursor line without one, or count lines from its last line, one per message line; the cursor on the last at the wanted column, a jump recorded; E749 on an empty buffer, E477 for a bang, E488 for flags.
- Let a global show together the lines each `:p` it runs printed, where it otherwise shows the last message a command gave.
- Let a dispatch run by keys `:normal` feeds, and a `LeaveInsert` there, join the open undo step instead of closing it.
- Place the cursor of the line commands through `EditorState#clamp_col`, and give `ExRange` the count of addresses typed, which `:j` reads instead of the range text.
- Fix the garbled range sentence of `docs/compatibility.md` and add the map entries of `RegisterCount.parse_count`, `Registers.unnamed?`, and `Buffer#transaction_size`.

Out of scope: `:normal!` skipping mappings (every Carat key is a keymap binding, so `!` runs the same keys); `:normal` reading `|`; the flags of `:p` (`l`, `#`) and `:P`, `:l`, `:nu`, `:#`; Neovim's 'maxmapdepth' option (the depth limit is fixed at 100).

Assumptions: the arguments of `:normal` are the text after the command name as `ExGrammar` keeps it; an empty buffer for E749 is one empty line; a `:{range}normal` stops at the buffer's last line when the keys deleted lines.

## Capabilities

### New Capabilities

### Modified Capabilities
- `line-commands`: adds `:normal` and `:p` and their refusals.
- `global`: a global shows together the lines its `:p` commands print.

## Impact

- Code: new `carat/use_cases/ex/normal_command_handler.rb` and `print_command_handler.rb`, `line_command_handler.rb`, `join_command_handler.rb`, `carat/domain/ex_range.rb`, `carat/domain/editor_state.rb`, `carat/use_cases/outcome.rb`, `carat/use_cases/dispatcher.rb`, `carat/use_cases/leave_insert.rb`, `carat/use_cases/search/global_command.rb`, `carat/adapters/editor_assembly.rb` (HandleKey built before the ex commands are registered).
- Tests: `test/editor_line_commands.rb`, `test/domain_ex_range.rb`, `test/use_cases_ex.rb`.
- Docs: `docs/compatibility.md` (rows for `:normal` and `:p`, the range sentence, Global), `docs/codebase-map.md` area 12, `docs/architecture.md` section 5.2.
- README.md: changed, the line commands list names `:normal` and `:p`.
- docs/architecture.md: changed, section 5.2 names `normal` and `p` among the editing ex commands.
