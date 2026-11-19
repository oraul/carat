## Why

Each key typed into the grep picker (`<leader>fg`) checks every stored line, up to 400,000, against the query: on this repository (about 148,000 lines) a key takes about 45 ms in the release build, against the rule that nothing waits on a key, and no bench scenario measures it. The 200 kept rows go to the best lines wherever they are, so a few files with many hits fill the list: for the query `explorer` on this repository 149 files hold a hit but the rows cover only 27, and the user could not find the file they wanted. A row also passes the bidirectional embedding, override, and isolate characters (U+202A to U+202E, U+2066 to U+2069) of an untrusted file to the terminal, so a row can show another path or line (sprint-20 review security Low (4)). Outside the roadmap of `docs/architecture.md` section 12: the user's Sprint 21 grep work on the finder plugin, the rest of finder-grep-b.

## What Changes

- Results spread across files: each matching file's best line ranks before any file's second line, then every file's second line, and so on, each round in the existing rank order (whole-word terms, hits, shorter path, listing order); within a file equal scores keep line order. The 200-row cap keeps that order, so a file with one hit is never pushed out by a file with more hits than the cap.
- The title counts files and lines: `Grep F of M files, L of N lines`, F the files the rows show, M the files with a matching line, L the matching lines, N the stored lines. It replaces `Grep K/N`; the row cap shows as L above the 200 rows.
- Each key's search is bounded: a key checks at most 30,000 stored lines from where its search starts; when the new text only extends the old one (every old term inside a new term), it checks the old matches again instead of every line and continues the scan where the last key stopped, with the budget the kept matches leave. While stored lines remain unchecked the title marks M and L with `+`; a key that does not extend the text starts again from the first line. A key thus checks at most 60,000 lines.
- A row shows each of U+202A to U+202E and U+2066 to U+2069 as a space, as it shows control characters.
- Tidy: `Grep.safe` and `Grep.utf8_size` become private instance methods, used only in `Grep`, and the class comment is rewritten to the wrap.
- A `grep` bench scenario types into the picker over 150 files of 1000 lines (150,000 lines), and `make bench-budget` prints its time per key after the allocation budget.
- No new host request and no API version bump. Out of scope: streaming the read and the search in the background (finder-streaming), the grep preview (finder-grep-preview), and any other code point.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-finder`: the grep picker's title, the row cap and its order across files, the per-key bound, and the safe rows.

## Impact

- Code: `carat/plugins/finder/grep.rb` (the search, the ranking, the counts, `safe`), tests in `test/editor_finder_grep.rb` and its snapshot; `bench/keys.rb` (the `grep` scenario) and the Makefile's `bench-budget` target.
- Memory: the matches of the last key are kept as one integer each, at most 30,000, so the next key can narrow them.
- Specs: file-finder (modified requirements: the picker's title, the row cap, rows shown safely, the ranking; an added requirement, the per-key bound).
- README.md: changed, the grep picker's title, spread, and bound, and what `make bench-budget` prints.
- docs/architecture.md: changed, section 10 names the grep scenario and what `make bench-budget` prints; no layer, port, or API change.
- docs/codebase-map.md: changed, the grep index, the finder area's bench line, and the bench flow.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action is added or changed.
- CLAUDE.md: unchanged, the Makefile's `bench-budget` keeps its name and its line in Commands, which does not list the scenarios it runs; no process change.
