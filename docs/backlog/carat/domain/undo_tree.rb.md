# Backlog: carat/domain/undo_tree.rb

### UndoTree#undo_seq and #redo_seq have no production caller
- Location: carat/domain/undo_tree.rb:173, :179
- Why: only tests call them and the map lists them as API (area 8). Folded into architecture-docs.
- Fix: drop them and assert through undo_path and redo_path, updating the map.
- Category: editor
- Added: 2026-11-17

### Dead code (sprint-20 sweep quality, undo_tree.rb:173)

- Location: `carat/domain/undo_tree.rb:173`
- Why: dead code: undo_seq has no caller anywhere (the comment at :185 says callers check it, but they use undo_path), and redo_seq (:179) is used only by test/domain_undo_tree.rb
- Fix: remove undo_seq, reword the :185 comment, and drop it from the area 9 map line (or test redo_seq through head_of(current))
- Also: test/domain_undo_tree.rb
- Category: editor
- Added: 2026-11-19
