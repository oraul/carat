## Context

`Grep` scored each stored line with `Matcher.span_score`, the path matcher's subsequence search, so a content search inherited fuzzy path semantics: scattered letters matched and the leftmost span, not the best hit, was scored.

## Decisions

- Substring terms, not a subsequence: the query is split at spaces into terms once per search (`split_terms`), and `line_score` finds each with `Matcher.find`, a first-byte scan with an ASCII-lowercase compare that allocates nothing. A missing term ends the line's scoring at once, so a line without the first term costs one scan.
- Whole word means a word start before the hit and a word end after it. `Matcher.boundary?` is a path rule that counts only `/ _ - .` and space (and a camel-case change) before a byte, so a quoted `'hello'` would rank as part-word; `word_start?` accepts the same starts and also any non-letter, non-digit byte before the hit (a quote, bracket, or operator), and `word_end?` is its mirror after the hit. A multi-byte character is a word byte on both sides.
- The score is 256 per term with a whole-word hit plus the total hits of the terms up to 255, fed to the unchanged `Matcher.key` with the path's length, so equal scores order by a shorter path then listing order, and the existing bounded top-200 selection is untouched.
- The column is the first hit of the first term, converted to characters, so the cursor lands on what the user typed first.
- `MAX_LINES` is 400,000: the repository's listing is about 148,000 lines, and the listing itself stops at 100,000 files, so 400,000 lines cover a tree of roughly that many files at an average of four lines; the key's 20-bit index holds 1,048,575.
- Longer files keep the host's first-1000-lines bound with no mark: a mark needs the host's read to report a cut, which is a new request.

## Risks

- Each key scans every stored line, now up to 400,000: about 45 ms per key on this repository at the release optimization. The per-key bound (a narrowing filter, a cap on lines scored, a partial selection) and its bench scenario are finder-grep-c's.
- The store grows to tens of megabytes on a large tree, held only while the picker is open.
