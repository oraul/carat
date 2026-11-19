## 1. Implementation

- [x] 1.1 Add Matcher.find, word_start?, and word_end?, allocation-free, with table tests
- [x] 1.2 Match Grep lines by substring terms in any order, ASCII case ignored, ranked by whole-word terms, hits, shorter path, listing order; a query with no term lists nothing
- [x] 1.3 Set the column to the first byte of the first term's hit
- [x] 1.4 Raise Grep::MAX_LINES to 400,000 and keep the capped mark on the stored count

## 2. Tests and docs

- [x] 2.1 Update test/editor_finder_grep.rb and its snapshot: scattered letters, a later contiguous hit, two terms in any order, whole-word ranking, case, the column, the 150,001-line tree, and the 400,000-line cap
- [x] 2.2 Update README.md, docs/actions.md, docs/plugins.md (the 1000-line file bound included), and the code map; the delta spec for file-finder
