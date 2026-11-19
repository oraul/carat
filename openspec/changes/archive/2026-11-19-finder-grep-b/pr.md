feat(finder): match grep lines by substring terms and search whole trees

## Summary

The grep picker now lists a line only when it holds every typed term as a case-insensitive substring, and it searches a tree of this repository's size whole. Typing Explorer used to list lines holding only scattered e, x, p, l, o, r, e, r, and the store stopped at 100,000 lines while this repository holds about 148,000, so about a third of its files were never searched.

---

## Changes

- Change grep matching to substring terms: the query is split at spaces and a line matches when it holds every term in any order, ASCII case ignored; scattered letters no longer match and an empty query lists nothing.
- Rank rows by terms found as whole words, then more hits of the terms in the line (up to 255), then a shorter path, then listing order, riding in the score of the unchanged key.
- Set the column of a picked row to the first byte of the first term's hit, converted to characters.
- Add allocation-free Matcher.find, word_start?, and word_end? for the grep search; Matcher.score and span_score, the file finder's path matching, are unchanged.
- Raise Grep::MAX_LINES from 100,000 to 400,000 and keep the plus after the stored count on the prompt when a larger tree still hits it.
- Document the substring terms, the larger store, and the 1000-line search bound of each file in docs/plugins.md, README.md, docs/actions.md, and the code map, and update the file-finder spec.
- Add table tests for scattered letters, a later contiguous hit, two terms in any order, whole-word ranking, case, the column, the hit-count clamp, a 150,001-line tree, and the 400,000-line cap.

---

## Testing

- Run the security review of the committed diff, no finding at any severity.
- Run the quality review of the committed diff, no blocking finding and no advisory in its last pass; its first pass blocked on an untested hit clamp, now tested.
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all exit 0.
- Run the benchmark review, no blocking finding.
- Run make spec-validate after archiving, 54 passed, 0 failed.
- Measure on this repository's 2,242 tracked files (122,855 stored lines, about 11 MB) at the release optimization: the picker opens in about 350 ms from an in-memory copy of the tree and each key takes about 45 ms.

---

## Notes

This delivers the matching and coverage part only. The per-key bound (a narrowing filter, a cap on lines scored, a partial top-200 selection), a grep bench scenario recording time per key, and the replacement of bidi and zero-width format code points in Grep.safe are not delivered here and are recorded as findings. The open-time read stays synchronous; streaming is finder-streaming's. A file longer than 1000 lines is searched in its first 1000 lines, the host's read limit, with no mark on its rows or the prompt. The store costs about 6.4 MB of integers plus the line strings at 400,000 lines, about 50 MB for typical source and near 190 MB at worst, held only while the picker is open.
