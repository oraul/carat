## 1. Search and rows

- [x] 1.1 Bound each key's search in `carat/plugins/finder/grep.rb`: keep the last key's matches, narrow them when the text extends, continue the scan within LINE_BUDGET; tests in `test/editor_finder_grep.rb` (the bound, the extended query, the backspace)
- [x] 1.2 Spread the rows across files round by round and title them `Grep F of M files, L of N lines` (`grep.rb`); tests in `test/editor_finder_grep.rb` (a one-hit file beside a file over the cap, the count line, line order among equal scores) and the updated titles
- [ ] 1.3 Show U+202A to U+202E and U+2066 to U+2069 as spaces in `Grep#safe`, make `safe` and `utf8_size` private, rewrap the class comment; a test row per code point in `test/editor_finder_grep.rb`

## 2. Bench and docs

- [ ] 2.1 Add the `grep` bench scenario to `bench/keys.rb` (150 files of 1000 lines) and print its time per key in `make bench-budget`; run `make bench-budget`
- [ ] 2.2 Update README.md, docs/architecture.md section 10, and docs/codebase-map.md
