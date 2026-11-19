feat(finder): spread grep rows across files and bound each key

## Summary

The grep picker now shows each matching file's best line before any file's second line, counts the matching files and lines in its title, bounds the lines each key checks, and shows bidirectional marks, zero-width characters, and line separators from file text as spaces. A few files with many hits filled all 200 rows (for the query explorer on this repository 149 files hold a hit but the rows covered 27), every key scanned every stored line at about 45 ms on a tree this size, and a crafted file line could make a row show another path or line.

---

## Changes

- Change the grep ranking to rounds across files: every matching file's best line in the existing rank order, then every file's second line, and so on, with line order kept among equal scores within a file, so the 200-row cap never pushes out a file with one hit
- Change the grep title from Grep K/N to Grep F of M files, L of N lines, marking M and L with a plus while stored lines remain unchecked
- Add a per-key bound in carat/plugins/finder/grep.rb: a key checks at most 30,000 stored lines from where its search starts, and when the text only extends the previous one it narrows the previous matches and continues the scan where the last key stopped
- Fix Grep#safe to show U+061C, U+200B to U+200F, U+2028 to U+202E, U+2066 to U+2069, and U+FEFF as spaces, as it shows control characters
- Refactor Grep.safe and Grep.utf8_size into private instance methods and rewrap the class comment
- Add a grep bench scenario in bench/keys.rb over 150 files of 1000 lines, which exits unless the picker stored every generated line, and run it in make bench-budget through bench/run.sh
- Add tests in test/editor_finder_grep.rb for the bound, the extended query, the backspace, a one-hit file beside a file over the row cap, the count line, line order among equal scores, and a row per replaced code point
- Change the file-finder spec for the title, the row cap and its order, the safe rows, and the ranking, and add the per-key bound requirement
- Document the spread, the counts, the bound, and the grep scenario in README.md, docs/plugins.md, docs/architecture.md section 10, and docs/codebase-map.md

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding and none blocking
- Run the quality review, pass with no blocking finding
- Run the benchmark review, pass with no blocking finding
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass, test-run reporting 114/114 passed
- Run make bench-budget, the grep scenario over 150,000 lines taking 25.3 ms per key in total (23.2 ms handling) against about 45 ms before
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

No new host request and no plugin API version bump. Streaming the read and the search in the background stays in finder-streaming, and the grep preview is the separate change finder-grep-preview. The other invisible format code points a row can still carry (U+2060 to U+2064, U+206A to U+206F, U+FFF9 to U+FFFB, U+180E, and the tag characters) are recorded in docs/findings/finder-grep-c.md; they cannot reorder runs or move the path and line prefix.
