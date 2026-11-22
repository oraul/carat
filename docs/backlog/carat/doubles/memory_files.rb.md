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
