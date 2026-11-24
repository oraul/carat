# Backlog: carat/domain/registers.rb

### An uppercase register append leaves unnamed holding only the piece at carat/domain/registers.rb:83 (sprint-28 sweep quality, note 21)

- Location: carat/domain/registers.rb:83, :104; test/editor_registers.rb:33
- Why: Vim and Neovim point unnamed at the register written, so `"Ayy` then `p` puts the whole of register a; carat puts the appended line, and the test asserts it.
- Fix: after an uppercase append set unnamed to the joined entry; the test row expects the whole register.
- Also: test/editor_registers.rb
- Category: editor
- Added: 2026-11-22

### Vim compatibility to verify: after an uppercase append the unnamed at carat/domain/registers.rb:83 (sprint-32 sweep quality, note 33)
- Location: carat/domain/registers.rb:83
- Why: Vim compatibility to verify: after an uppercase append the unnamed register holds only the appended piece (asserted in test/editor_registers.rb:33), while Vim's get_yank_register points the unnamed register at the written register, so p pastes the whole appended register
- Fix: confirm against Neovim and, if it differs, store the joined entry as unnamed and update the test
- Category: quality
