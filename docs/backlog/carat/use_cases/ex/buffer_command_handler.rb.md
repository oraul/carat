# Backlog: carat/use_cases/ex/buffer_command_handler.rb

## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?

- Where: `digits?` in `carat/use_cases/ex/buffer_command_handler.rb` (line 98 at `buffer-list`) and `HistoryCommandHandler.digits?` in `carat/use_cases/ex/history_command_handler.rb` (line 65). Quality advisory of `buffer-list`.
- Why it matters: two copies of one check drift apart.
- Fix outline: keep one shared helper and call it from both handlers. Queued as `buffer-list-structure` in `docs/queue.md`.
- Also: carat/use_cases/ex/history_command_handler.rb
- Category: editor
- Added: 2026-11-05

## A buffer number with leading zeros past nine bytes reads as the largest

- Where: `number_in` in `carat/use_cases/ex/buffer_command_handler.rb` (line 92 at `buffer-list`). Quality advisory of `buffer-list`.
- Why it matters: any argument over 9 bytes maps to `LARGEST`, so `:b 0000000001` reports E86 and `:bn 0000000002` steps a wrong count, unlike Neovim.
- Fix outline: skip leading zeros before the length check, with a table row for each spelling. Queued as `buffer-list-tidy` in `docs/queue.md`.
- Category: editor
- Added: 2026-11-05

## Ex and visual code copy domain helpers

- Where: `carat/use_cases/ex/buffer_command_handler.rb:101` (`digits?` repeats the public `HistoryCommandHandler.digits?` at `history_command_handler.rb:65`); `carat/use_cases/ex/register_command_handler.rb:61` (repeats `RegisterEntry#lines` at `register_entry.rb:42`); `carat/use_cases/visual/put_over_selection.rb:124` (repeats the linewise count loop of `Operators.put` at `operators.rb:42`). Periodic quality at 9a92265.
- Why it matters: copies drift; the put copy also carries the uncapped count.
- Fix outline: one domain helper each. Queue items `editing-counts` (the put copy) and backlog batches (copies).
- Also: carat/use_cases/ex/register_command_handler.rb, carat/use_cases/visual/put_over_selection.rb
- Category: editor
- Added: 2026-11-10

### duplication: the ASCII digit-run predicate digits? is copied verbatim at carat/use_cases/ex/buffer_command_handler.rb:102 (sprint-26 sweep quality, note 25)

- Location: carat/use_cases/ex/buffer_command_handler.rb:102
- Why: duplication: the ASCII digit-run predicate digits? is copied verbatim in carat/use_cases/ex/tab_command_handler.rb:102 and carat/use_cases/ex/history_command_handler.rb:61 (public self.digits?, which the map lists)
- Fix: one domain function (for example ExGrammar.digits?) called by all three handlers, the map updated
- Also: carat/use_cases/ex/tab_command_handler.rb, carat/use_cases/ex/history_command_handler.rb
- Category: editor
- Added: 2026-11-22
