# Backlog: carat/doubles/memory_files.rb

### MemoryFiles#write checks the unwritable path unnormalized (sprint-24 sweep quality)

- Location: `carat/doubles/memory_files.rb:121`
- Why: every other method normalizes with `key(path)`, so two spellings of one file behave differently.
- Fix: compare normalized paths.
- Category: editor
- Added: 2026-11-21

### MemoryFiles ignores dangling links and padding in rename, delete, mkdir, put at carat/doubles/memory_files.rb:237 (sprint-28 review quality note 1, sweep note 31)

- Location: carat/doubles/memory_files.rb:65, :151, :228, :237, :248
- Why: a renamed padded file loses its padding and the old path keeps it, put keeps a stale padding write drops, deleting a dangling link raises where DiskFiles removes it, mkdir over one succeeds; the double drifts from the driver.
- Fix: treat a dangling link as an entry there; move the @dangling and @padding keys in rename (an Integer-typed move_keys), clear them in delete and put.
- Category: editor
- Added: 2026-11-22

### mkdir and mkdir_private make a directory over a path at carat/doubles/memory_files.rb:248 (sprint-30 sweep quality, note 40)

- Location: carat/doubles/memory_files.rb:248
- Why: mkdir and mkdir_private make a directory over a path that holds a link, which Dir.mkdir refuses with EEXIST and MemoryFiles#create refuses (line 162), so a test of the recent files' mkdir_private over a planted link passes on the double and fails on disk
- Fix: add @links.key?(k) to mkdir's exists check
- Category: editor
- Added: 2026-11-23

### rename moves files, dirs, links, specials, and owner_only but at carat/doubles/memory_files.rb:264 (sprint-30 sweep quality, note 66)

- Location: carat/doubles/memory_files.rb:264
- Why: rename moves files, dirs, links, specials, and owner_only but not @padding or @dangling, and delete (282) leaves @padding, so a padded file renamed loses its size and a new file put at a deleted padded path inherits it, unlike DiskFiles
- Fix: move and drop @padding and @dangling with the other tables (a move_keys for Hash[String, Integer]) and add a drivers-parity test
- Category: editor
- Added: 2026-11-23

### write and create_private (172) compare the raw path with at carat/doubles/memory_files.rb:148 (sprint-30 sweep quality, note 67)

- Location: carat/doubles/memory_files.rb:148
- Why: write and create_private (172) compare the raw path with unwritable, while every other method keys by the absolute path, so a relative and an absolute spelling of one file differ
- Fix: compare key(path) against the keyed unwritable entries
- Category: editor
- Added: 2026-11-23
