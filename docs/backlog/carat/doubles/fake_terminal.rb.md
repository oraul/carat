# Backlog: carat/doubles/fake_terminal.rb

## FakeTerminal#input? is called by no test

- Where: `FakeTerminal#input?` in `carat/doubles/fake_terminal.rb` (line 55 at 5b128b5). Periodic quality at 5b128b5.
- Why it matters: dead code in a double a reader must check before trusting what the tests exercise.
- Fix outline: delete it.
- Category: editor
- Added: 2026-11-05
