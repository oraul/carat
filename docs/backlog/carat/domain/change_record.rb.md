# Backlog: carat/domain/change_record.rb

## ChangeRecord#delta and UndoTree#redo_seq have no production caller

- Where: `carat/domain/change_record.rb:18`, `carat/domain/undo_tree.rb:179` (periodic quality at 5722559).
- Why it matters: dead code read only by `test/domain_edits.rb` and `test/domain_undo_tree.rb`, and the map lists `redo_seq` as API.
- Fix outline: drop both, assert the record's removed and inserted lengths and the redo path in the tests, and remove `redo_seq` from area 9 of the map.
- Also: carat/domain/undo_tree.rb, test/domain_edits.rb, test/domain_undo_tree.rb
- Category: editor
- Added: 2026-11-07
