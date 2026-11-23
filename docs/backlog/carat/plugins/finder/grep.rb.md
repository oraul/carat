# Backlog: carat/plugins/finder/grep.rb

### Grep picker reads every file synchronously when it opens
- Location: carat/plugins/finder/grep.rb, Grep#load
- Why: a large tree makes the editor wait once at open (one read_file call per file, up to 100,000 stored lines); the user's nothing-waits rule is only met by bounding it.
- Fix: stream the read as a background task once finder-streaming and plugin-tasks land after spinel-bump, searching what has arrived.
- Category: plugins
- Added: 2026-11-19

### Grep helper duplication with the plugin
- Location: carat/plugins/finder/grep.rb (strings, ints), carat/plugins/finder/plugin.rb (no_paths)
- Why: the typed-empty array helpers repeat across two classes of one plugin.
- Fix: one shared helper per type in the plugin directory, used by both.
- Also: carat/plugins/finder/plugin.rb
- Category: plugins
- Added: 2026-11-19

### Column_at puts the cursor on the line's first byte equal to the query's (sprint-20 sweep quality, grep.rb:137)

- Location: `carat/plugins/finder/grep.rb:137`
- Why: column_at puts the cursor on the line's first byte equal to the query's first byte, not on the start of the match Matcher scored (span_score tightens to a later span), so 'abc' over 'a = x; abc' opens at column 0, away from the hit; the file-finder spec encodes the same weak rule
- Fix: answer the tightened span's start from Matcher (a span_start beside span_score), amend the spec's picking requirement, and add a test row where the first occurrence precedes the match
- Category: plugins
- Added: 2026-11-19

### Grep.safe passes bidi and zero-width format code points into rows
- Location: carat/plugins/finder/grep.rb (Grep.safe, Grep.utf8_size, and the class comment wrap)
- Why: U+202A to U+202E and U+2066 to U+2069 from untrusted files reach the rows, so a row can show another path or line; Grep.safe and Grep.utf8_size are public though used only inside Grep, and the class comment overruns the wrap. Not delivered by finder-grep-b.
- Fix: replace those code points in Grep.safe, make Grep.safe and Grep.utf8_size private class methods, rewrap the class comment, with a test row per replaced code point.
none
- Category: plugins
- Added: 2026-11-20

### Grep rows still pass the other invisible format code points

- Location: carat/plugins/finder/grep.rb:221 (`format_control?`), security Low (3)
- Why: the word joiner and invisible operators U+2060 to U+2064, the deprecated format controls U+206A to U+206F, the interlinear annotation marks U+FFF9 to U+FFFB, the tag characters U+E0001 and U+E0020 to U+E007F, and U+180E pass from untrusted file text into grep rows, so a crafted file line could hide characters in a row; they cannot reorder runs or move the path:line prefix, since every bidi embedding, override, isolate, and mark is already replaced.
- Fix: widen `format_control?` to every Unicode Cf code point a row can carry (add U+2060 to U+2064, U+206A to U+206F, U+FFF9 to U+FFFB, U+180E, and U+E0000 to U+E007F), and add one test row per added range in test/editor_finder_grep.rb.
- Also: test/editor_finder_grep.rb
- Category: security
- Added: 2026-11-20

### The grep picker's file reads stay synchronous on the editor thread
- Location: carat/plugins/finder/grep.rb load (host.read_file per listed file)
- Why: the byte budget (READ_BUDGET, 16 MiB) bounds the work of one opening but the reads still run on the editor thread; up to 16 MiB is read before the first frame of the picker.
- Fix: read the files in slices across idle ticks, or lazily on the first typed key, with the cap mark shown while the load runs.
- Category: plugins
- Added: 2026-11-23
