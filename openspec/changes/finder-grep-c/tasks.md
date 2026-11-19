## 1. Search and rows

- [x] 1.1 Bound each key's search in `carat/plugins/finder/grep.rb`: keep the last key's matches, narrow them when the text extends, continue the scan within LINE_BUDGET; tests in `test/editor_finder_grep.rb` (the bound, the extended query, the backspace)
- [x] 1.2 Spread the rows across files round by round and title them `Grep F of M files, L of N lines` (`grep.rb`); tests in `test/editor_finder_grep.rb` (a one-hit file beside a file over the cap, the count line, line order among equal scores) and the updated titles
- [x] 1.3 Show U+202A to U+202E and U+2066 to U+2069 as spaces in `Grep#safe`, make `safe` and `utf8_size` private, rewrap the class comment; a test row per code point in `test/editor_finder_grep.rb`

## 2. Bench and docs

- [x] 2.1 Add the `grep` bench scenario to `bench/keys.rb` (150 files of 1000 lines) and print its time per key in `make bench-budget`; run `make bench-budget`
- [x] 2.2 Update README.md, docs/plugins.md, docs/architecture.md section 10, and docs/codebase-map.md; make docs-lint

## 3. Review fixes

- [x] 3.1 Show U+061C, U+200B to U+200F, U+2028, U+2029, and U+FEFF as spaces in `Grep#safe` (security Low (5)); a test row per code point in `test/editor_finder_grep.rb`
- [x] 3.2 Qualify the synced requirements The picker reads the finder's files once and within bounds and Typing lists the matching lines best first by the per-key bound in the delta spec, and the test comment of the 30,000-line check
- [x] 3.3 Make the bench `grep` scenario exit unless the picker stored every generated line (`bench/keys.rb`)
- [x] 3.4 Run the `grep` scenario of `make bench-budget` through `bench/run.sh`, its allocation runs at 20 and 120 keys
- [x] 3.5 Name the bidirectional marks, zero-width characters, and line separators `Grep#safe` shows as spaces in README.md and docs/codebase-map.md (quality advisory README.md:58)
