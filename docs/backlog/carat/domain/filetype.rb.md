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
