## Why

`<leader>ff` finds a file only by its path. A user who remembers what a file contains has no way to find it, so the finder gains a picker over file contents.

## What Changes

- The finder plugin declares `plugin.finder.grep`, bound by its manifest to `<leader>fg` and listed in the palette. It opens the finder's list, prompt, and picks over the lines of the project's files.
- A new `Finder::Grep` reads each listed file once when the picker opens through the existing `read_file` host request, so at most its first 1000 lines of a file of at most 256 KiB are searched; the host drops carriage returns before it answers, so a CRLF line shows and matches without one. Files that fail to read, and files with a NUL byte, are skipped; a line is cut at a character boundary at or under 400 bytes; loading stops at 100,000 stored lines.
- Each key scores every stored line from byte 0 with the existing `Matcher.span_score` and `Matcher.key` (the path length slot holds the file path's length), keeps the best 200, and shows each as `path:line: text`. The title reads `Grep kept/stored`, a count followed by `+` when a cap cut it short.
- Enter, split, vertical split, and tab picks open the file as in the file finder, then call the existing `move_cursor` request with the line and the column, counted in characters, of the first line byte equal to the query's first byte (ASCII case ignored). No preview shows, so a key reads no file.
- Row text goes through `Grep.safe`: control characters become spaces and invalid UTF-8 bytes become question marks, so a file cannot send an escape sequence to the terminal.
- No new host request and no API version bump. Streaming the read as a background task is not part of this change: it belongs to finder-streaming and plugin-tasks, after spinel-bump. The read is synchronous and happens once per open of the picker.

## Impact

- Specs: file-finder (added requirements).
- Code: `carat/plugins/finder/plugin.rb`, new `carat/plugins/finder/grep.rb`; tests in new `test/editor_finder_grep.rb`.
- README.md, docs/actions.md, docs/plugins.md, docs/codebase-map.md: the grep picker described.
- docs/architecture.md: unchanged, no layer, port, or API change; the finder's picker uses existing requests.
- docs/compatibility.md: unchanged, no Neovim command is implemented.
- CLAUDE.md: unchanged, no process change.
