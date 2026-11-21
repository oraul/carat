# Backlog: carat/use_cases/windows/tab_request.rb

## Small findings of the periodic review at 186ddfb

- Where: dead code `TabRequest#counted?` (`carat/use_cases/windows/tab_request.rb` line 13), `UndoTree#undo_seq` and `#redo_seq` (`carat/domain/undo_tree.rb` lines 173 and 179, with the stale comment at 185), the dead store `row = top` (`carat/domain/motions.rb` line 579), `DisplayWidth.of_char` (`display_width.rb` line 133), `DecodedLine#cells` (line 91), `Cell#same?` (line 286); `Config#binding?`'s comment (`carat/domain/config.rb` line 205) omits the leader lines and lines of other word counts it keeps; the finder's `open_path` and `report` (`carat/plugins/finder/plugin.rb` line 314) copy the explorer's (lines 277 and 534); the finder matcher's helpers (`matcher.rb` line 55) are public and `lower(b)` takes a one-letter name; `PluginRouter#answer` (line 77) hands the plugin `prompt_id` uncopied; the explorer's `@followed` (`carat/plugins/explorer/plugin.rb` line 420) stays on the old path after its parent directory is renamed; `Frame::REPLACEMENT` (`frame.rb` line 36) repeats `Utf8::REPLACEMENT`. Periodic quality at 186ddfb, queued in the backlog batches. Raised again at ce6abdb (periodic quality): the `UndoTree` readers and the stale comment at 185, queue item `editing-counts`.
- Why it matters: dead surface and map mentions, a misleading comment, two open dispatches, a strings-copied breach, a mark on a path that no longer exists.
- Fix outline: delete the dead code and its map mentions; fix the comment; one `PluginApi` opening helper or an entry per plugin; `private_class_method` where Spinel allows and `byte`; `id.dup`; `@followed = tree.marked` after `tree.moved` with a directory-rename case; `REPLACEMENT = Utf8::REPLACEMENT`.
- Also: carat/domain/undo_tree.rb, carat/domain/motions.rb, carat/domain/config.rb, carat/plugins/finder/plugin.rb, carat/plugins/explorer/plugin.rb
- Category: editor
- Added: 2026-11-10
