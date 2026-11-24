# Backlog: carat/domain/filetype.rb

### Filetype cuts names by hand and slices by character

- Location: carat/domain/filetype.rb:29 and :81 (sprint-4 sweep, quality).
- Why: from_name repeats Paths.basename and FileIcons.file_type; program_type slices by character with a byte count.
- Fix: Paths.basename and one extension helper; byteslice.
- Category: editor
- Added: 2026-11-14

### Two file-name classifiers (architecture-review R2)

Location: `carat/domain/filetype.rb:8-11` (`EXTENSIONS`, `NAMES`) and `carat/plugin_api.rb:424-481` (`FileIcons::NAMES`, `file_type`). Why: both map a name or extension to a kind (`rb` to `ruby` in each), so a new language is added twice and the two can disagree. Fix outline: one table in `carat/plugin_api.rb` (rank 0) that `Filetype` reads, the icon-only names apart, or `FileIcons` taking the filetype the host already detected.
- Also: carat/plugin_api.rb
- Category: editor
- Added: 2026-11-15

### config.ru in NAMES is dead, since the ru extension at carat/domain/filetype.rb:13 (sprint-30 sweep quality, note 81)

- Location: carat/domain/filetype.rb:13
- Why: config.ru in NAMES is dead, since the ru extension already maps to ruby; and the core table hard-codes Ruby extensions, names, and shebang programs while plugins declare filetypes, so a language plugin needs a core edit
- Fix: drop config.ru, and record a backlog item to let a manifest declare its extensions
- Category: editor
- Added: 2026-11-23

### NAMES entry config.ru is redundant with EXTENSIONS ru at carat/domain/filetype.rb:13 (sprint-32 sweep quality, note 43)
- Location: carat/domain/filetype.rb:13
- Why: NAMES entry config.ru is redundant with EXTENSIONS ru
- Fix: drop it
- Category: quality
