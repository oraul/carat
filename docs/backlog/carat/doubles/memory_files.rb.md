# Backlog: carat/doubles/memory_files.rb

### MemoryFiles#write checks the unwritable path unnormalized (sprint-24 sweep quality)

- Location: `carat/doubles/memory_files.rb:121`
- Why: every other method normalizes with `key(path)`, so two spellings of one file behave differently.
- Fix: compare normalized paths.
- Category: editor
- Added: 2026-11-21
