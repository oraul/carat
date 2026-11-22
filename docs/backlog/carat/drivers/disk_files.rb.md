# Backlog: carat/drivers/disk_files.rb

### stat reads four more path stats outside the rescue at carat/drivers/disk_files.rb:82 (sprint-27 review quality, note 4)

- Location: carat/drivers/disk_files.rb:82
- Why: the comment says one File.stat, but docs/spinel-notes.md says a Spinel File::Stat keeps its path and each reader (size, mtime, directory?, file?) runs stat(2) again, so a path removed between them escapes the FilePort promise of PathInfo.missing.
- Fix: correct the comment and read size, mtime, directory? and file? inside the begin/rescue so a vanished path gives PathInfo.missing; a test with a path removed after the first stat.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-22
