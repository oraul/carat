# Backlog: carat/domain/registers.rb

### An uppercase register append leaves unnamed holding only the piece at carat/domain/registers.rb:83 (sprint-28 sweep quality, note 21)

- Location: carat/domain/registers.rb:83, :104; test/editor_registers.rb:33
- Why: Vim and Neovim point unnamed at the register written, so `"Ayy` then `p` puts the whole of register a; carat puts the appended line, and the test asserts it.
- Fix: after an uppercase append set unnamed to the joined entry; the test row expects the whole register.
- Also: test/editor_registers.rb
- Category: editor
- Added: 2026-11-22
