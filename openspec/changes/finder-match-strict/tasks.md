## 1. Matcher

- [x] 1.1 Add test rows that fail on the old matcher (a scattered path, initials, mid-word runs, terms, the rank of explorer) in `test/plugins_finder_matcher.rb`, in their own commit
- [x] 1.2 Replace the subsequence scoring in `carat/plugins/finder/matcher.rb` with the two tiers, the terms, `blank?`, and `find_in`; `Plugin#filter` lists a blank query in listing order
- [x] 1.3 Add editor rows to `test/editor_finder.rb` (terms, initials, mid-word, spaces, the scattered path with the rank of explorer, multi-byte) and fix the 10,000-file count; rewrite both snapshots

## 2. Docs

- [x] 2.1 Update README.md, docs/plugins.md, and docs/codebase-map.md; make docs-lint

## 3. Checks

- [x] 3.1 Run `make gates`, `make spec-validate`, and the touched tests; hold the finder bench's allocations per key with `make bench-budget`
