# Backlog: carat/domain/search_pattern.rb

## Records and values miss pins or say why not

- Where: `carat/domain/search_pattern.rb` line 10 (the regexp pin dropped with no comment); `carat/domain/find.rb` line 4 and `command.rb`, `ex_command.rb`, `key_notation.rb`, `keymap_match.rb`, `position.rb`, `range.rb` (no member pins); `carat/domain/history.rb` line 23 (`super()` without keywords, uncommented); `carat/domain/transaction.rb` line 297 (`merged?` rewrites the last record, a command named as a predicate). Periodic quality at e49f63d.
- Why it matters: against the inline RBS and naming rules of CLAUDE.md, and a reader cannot tell an omission from a Spinel workaround.
- Fix outline: add the pins or a one-line comment citing `docs/spinel-notes.md`, and rename `merged?` or list it in `BOOL_COMMANDS`. Queue item: Backlog batches.
- Also: carat/domain/find.rb, carat/domain/history.rb, carat/domain/transaction.rb, CLAUDE.md, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-10
