## 1. Matcher

- [x] 1.1 Add test rows that fail on the old matcher (a scattered path, initials, mid-word runs, terms, the rank of explorer) in `test/plugins_finder_matcher.rb`, in their own commit
- [x] 1.2 Replace the subsequence scoring in `carat/plugins/finder/matcher.rb` with the two tiers, the terms, `blank?`, and `find_in`; `Plugin#filter` lists a blank query in listing order
- [x] 1.3 Add editor rows to `test/editor_finder.rb` (terms, initials, mid-word, spaces, the scattered path with the rank of explorer, multi-byte) and fix the 10,000-file count; rewrite both snapshots

## 2. Docs

- [x] 2.1 Update README.md, docs/plugins.md, and docs/codebase-map.md; make docs-lint

## 3. Checks

- [x] 3.1 Run `make gates`, `make spec-validate`, and the touched tests; hold the finder bench's allocations per key with `make bench-budget`

## 4. Review fixes

- [x] 4.1 Prove the spec's tie-break by all the terms together: add the row `lib beta` over `lib/beta_x.rb` and `lib/xbeta.rb` (equal worst term, sums 12 and 11, the longer path first) to `test/plugins_finder_matcher.rb`, and relabel the worst-term row; both fail with the sum dropped
- [x] 4.2 Replace the two tier 1 loops of `Matcher.term_score` with one `substring_score` helper
- [x] 4.3 Define the tier 1 constants from `MAX_RUNS`, so raising it keeps every substring above every run match
- [x] 4.4 Give the spec scenario's label to the `alpha`/`beta` row of the matcher test and relabel the `a_pl` row, in the test and its snapshot
- [x] 4.5 Say in docs/plugins.md that both pickers refuse scattered letters, the file finder also matching initials
- [x] 4.6 Describe substring or initials matching in the finder's rows of docs/compatibility.md and docs/actions.md
- [x] 4.7 Add `substring_score` to the matcher.rb entry of docs/codebase-map.md
