### A file longer than 1000 lines is searched in part with no mark
- Location: carat/plugins/finder/grep.rb (FILE_ROWS, `load`), carat/use_cases/plugins/file_requests.rb (the `read_file` row limit)
- Why: the user can search a long file and miss a line past its 1000th with nothing on the rows or the title saying the file was cut; docs/plugins.md now states the bound but the picker does not show it.
- Fix: have `read_file` report that rows were dropped (a host request change with a minor version bump), then count the cut files in `Grep` and show a note on the title or the prompt's count.

### Grep per-key cost is unbounded and has no bench scenario
- Location: carat/plugins/finder/grep.rb (the per-key scan of every stored line, up to 400,000), bench/
- Why: each key scans every stored line (about 45 ms per key on this repository) against the nothing-waits rule, and no bench scenario records time per key under make bench-budget; finder-grep-b delivered the matching and coverage part only.
- Fix: bound the per-key work (a narrowing filter over the previous query's matches when the query extends it, a cap on lines scored with the capped note, a partial top-200 selection) and add a grep bench scenario on a tree of at least this repository's size.

### Grep.safe passes bidi and zero-width format code points into rows
- Location: carat/plugins/finder/grep.rb (Grep.safe, Grep.utf8_size, and the class comment wrap)
- Why: U+202A to U+202E and U+2066 to U+2069 from untrusted files reach the rows, so a row can show another path or line; Grep.safe and Grep.utf8_size are public though used only inside Grep, and the class comment overruns the wrap. Not delivered by finder-grep-b.
- Fix: replace those code points in Grep.safe, make Grep.safe and Grep.utf8_size private class methods, rewrap the class comment, with a test row per replaced code point.
none
