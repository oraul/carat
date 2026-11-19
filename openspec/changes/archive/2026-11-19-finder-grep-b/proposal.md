## Why

The grep picker (`<leader>fg`) lists a line when the query's bytes appear in it in order, so typing `Explorer` also lists lines holding only scattered e, x, p, l, o, r, e, r, and ranks a later contiguous hit below the scattered span before it. It also stops loading at 100,000 stored lines while this repository holds about 148,000 (at most 1000 per file), so about a third of the files are never searched. A content search should list the lines that hold what was typed.

## What Changes

- A line matches only when it holds every term of the query as a substring, ASCII case ignored; the terms are the runs of bytes between spaces, in any order, and a query with no term (empty, or only spaces) lists nothing and shows the hint. Scattered letters no longer match.
- Rows rank by the terms found as a whole word (a word start before and a word end after, each by a letter, digit, multi-byte character, or lower-to-upper camel-case change; a quote, bracket, or other punctuation ends a word), more such terms first, then more hits of the terms in the line (counted up to 255), then a shorter path, then listing order. The ranking rides in `Matcher.key`'s score as 256 per whole-word term plus the hit count.
- The column of a picked row is the first byte of the first hit of the query's first term (`Grep#column_at`), where it was the first line byte equal to the query's first byte.
- `Matcher` gains `find`, `word_start?`, and `word_end?`, allocation-free; `Matcher.score` and `span_score`, the file finder's path matching, are unchanged.
- `Grep::MAX_LINES` rises from 100,000 to 400,000 so this repository's tree is searched whole; the title keeps its `+` after the stored count when a larger tree still hits the cap. A file is still searched in its first 1000 lines, the host's read limit, and docs/plugins.md says so (a longer file's rows and the title carry no mark of it).
- No new host request and no API version bump. Streaming the read stays with finder-streaming.

## Impact

- Memory: lines are stored as one string each plus two integers (file index and line number; the hit slots are kept only for the shown rows), so 400,000 lines cost about 16 bytes of integers each, about 6.4 MB, plus each string at most 400 bytes and its object header: about 50 MB for typical source lines of 40 to 60 bytes, at worst near 190 MB when every line is cut at 400 bytes. The line index stays within `Matcher.key`'s 20 bits (1,048,575). The store lives only while the picker is open.
- Open time: measured on this repository's 2,242 tracked files (122,855 stored lines, about 11 MB) at the release optimization, the picker opens in about 350 ms from an in-memory copy of the tree, and each key takes about 45 ms; the read stays synchronous, and the per-key bound is the next change's.
- Specs: file-finder (modified requirements: the bounds, typing lists the matching lines, picking a row).
- Code: `carat/plugins/finder/grep.rb`, `carat/plugins/finder/matcher.rb`, the palette text in `carat/plugins/finder/plugin.rb`; tests in `test/editor_finder_grep.rb` and `test/plugins_finder_matcher.rb`.
- README.md, docs/actions.md, docs/plugins.md, docs/codebase-map.md: the substring matching, the larger store, and the 1000-line file bound described.
- docs/architecture.md: unchanged, no layer, port, or API change.
- docs/compatibility.md: unchanged, no Neovim command is implemented.
- CLAUDE.md: unchanged, no process change.
