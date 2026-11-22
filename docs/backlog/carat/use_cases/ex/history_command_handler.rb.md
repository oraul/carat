# Backlog: carat/use_cases/ex/history_command_handler.rb

## :earlier and :later take no time or write count

- Where: `Carat::UseCases::HistoryCommandHandler#travel` in `carat/use_cases/ex/history_command_handler.rb`, which answers `Not implemented: :earlier 10s` for an argument ending in `s`, `m`, `h`, `d`, or `f`, and `Carat::Domain::UndoTree` in `carat/domain/undo_tree.rb`, which keeps each state's time and write number but no search over them.
- Why it matters: Neovim's `:earlier 10m` and `:later 1f` move through the undo tree by time and by file writes, the quickest way back to the text of an earlier session of work; the `undo-and-registers` change implemented counts of changes only.
- Fix outline: give `UndoTree` a `seq_at_time(time, older)` that returns the last state made at or before (or the first after) a time, and a `seq_at_save(n, older)` over the write numbers, both over the flat arrays the tree already keeps; have the handler convert `Ns`, `Nm`, `Nh`, and `Nd` to seconds from the clock port and call `Undo#to` with the state found, and `Nf` count writes as Neovim does (`:earlier 1f` goes to the last write, or before the first change when there is none); move the tests in `test/editor_undo.rb` from the "Not implemented" message to the states reached.
- Also: carat/domain/undo_tree.rb, test/editor_undo.rb
- Category: editor
- Added: 2026-11-01

## The ex digit readers are four, and one is uncapped

- Where: `carat/use_cases/ex/history_command_handler.rb:43` and :75 (`:undo N`, `:earlier N`, `:later N` feed `args.to_i` unbounded), beside `ExRange.line_number`, `RegisterCount`, and `BufferCommandHandler#number_in`/`digits?` (buffer_command_handler.rb:101). Periodic quality at bd86828.
- Why it matters: a 20-digit count reaches the history walk, the overflow `number_in` exists to prevent.
- Fix outline: one bounded digit reader for all four, with rows for a 20-digit `:undo` and `:earlier`. Queue item `editing-counts`.
- Category: editor
- Added: 2026-11-11

### History counts are unbounded and digits? is written four times

- Location: carat/use_cases/ex/history_command_handler.rb:44 and :77; `digits?` at buffer_command_handler.rb:102, tab_command_handler.rb:102, history_command_handler.rb:67, carat/domain/json.rb:72. Sprint-6 sweep, quality. Queue item `ex-handlers-tidy`.
- Why: `:undo N`, `:earlier N`, and `:later N` convert an unbounded run of digits while the buffer and tab handlers hold theirs to 9 bytes for Spinel's Integer.
- Fix outline: one domain predicate with the 9-digit bound the three handlers share, with a test for a long count.
- Also: carat/domain/json.rb
- Category: editor
- Added: 2026-11-15

### Not implemented is a success in one handler and a failure in another

- Location: carat/use_cases/ex/history_command_handler.rb:78 against buffer_command_handler.rb:69 and :88. Sprint-6 sweep, quality advisory. Queue item `ex-handlers-tidy`.
- Why: the same answer is shown with two outcomes.
- Fix outline: one form for every unimplemented argument.
- Category: editor
- Added: 2026-11-15

### Duplication (sprint-20 sweep quality, history_command_handler.rb:61)

- Location: `carat/use_cases/ex/history_command_handler.rb:61`
- Why: duplication: digits? is defined again privately in buffer_command_handler.rb:102 and tab_command_handler.rb:102, and this public class method is used only in its own file
- Fix: one shared helper (a protected ExHandler method or an ex concern) and remove the three copies
- Category: editor
- Added: 2026-11-19

### Consistency (sprint-20 sweep quality, history_command_handler.rb:74)

- Location: `carat/use_cases/ex/history_command_handler.rb:74`
- Why: consistency: the literal E474 message sits beside Domain::Messages.invalid_argument at :88 and repeats messages_command_handler.rb:27
- Fix: add one E474 message to Domain::Messages and use it in both handlers
- Category: editor
- Added: 2026-11-19

### duplication: the literal "E474: Invalid argument" is spelled here at carat/use_cases/ex/history_command_handler.rb:74 (sprint-26 sweep quality, note 26)

- Location: carat/use_cases/ex/history_command_handler.rb:74
- Why: duplication: the literal "E474: Invalid argument" is spelled here and in carat/use_cases/ex/messages_command_handler.rb:27 (with an argument three times in set_command_handler.rb) while Domain::Messages holds the shared messages
- Fix: a Messages::E474 constant and an invalid_value(text) helper used by all
- Also: carat/use_cases/ex/messages_command_handler.rb
- Category: editor
- Added: 2026-11-22
