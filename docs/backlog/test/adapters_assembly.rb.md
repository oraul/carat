# Backlog: test/adapters_assembly.rb

## Two assembly test labels name too few holders

- Where: the labels `the last search, in the searches and the substitute` and `the search history, in the searches and the substitute` in `test/adapters_assembly.rb` lines 103 and 104 at 4f653d2. Two quality advisories in `implement-contracts`.
- Why it matters: the rows now also check the command line, the prompt, and the frame presenter, so the labels mislead a reader of a failure.
- Fix outline: shorten them to `the last search` and `the search history` and rewrite the snapshot with `make snapshots`.
- Category: code-quality
- Added: 2026-11-07

### :normal and :p tests and docs miss what the code promises (vim-line-commands-c late findings)

- Where: `test/adapters_assembly.rb:126`, `test/editor_line_commands.rb:171`, `:176`, `carat/use_cases/ex/print_command_handler.rb:34`, `docs/architecture.md:200`, `carat/use_cases/dispatcher.rb:75`, at 522a0e1.
- Why it matters: the one-instance check names only the controller though `NormalCommandHandler` holds `HandleKey` in a reader; a scenario comment sits above the wrong rows (sprint-17 review); only `:undo` is tested of the four undo commands `docs/compatibility.md` promises sync under `:normal`; E749 is given for one empty line where Neovim prints it, not listed as a difference; section 6 names `Outcome` as ok and message, without printed; `transaction_edits` is read for every dispatched key though only record uses it.
- Fix outline: add the holder to the strangers list, move the comment, add a `:redo` row, list E749 under Differences, name `printed` and `Outcome.from_print`, read the edits inside the change branch. Queued in `normal-command-fixes`.
- Also: test/editor_line_commands.rb, carat/use_cases/ex/print_command_handler.rb, docs/architecture.md, carat/use_cases/dispatcher.rb, docs/compatibility.md
- Category: code-quality
- Added: 2026-11-18
