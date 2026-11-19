## Context

At 290cd4a `Grep#search` (`carat/plugins/finder/grep.rb:63`) checks every stored line with `line_score` and keeps a partial top 200 of the `Matcher.key` keys (score, shorter path, earlier index), cutting the list to 200 each time it reaches 800. Nothing survives between keys but the terms. Lines are stored file by file in listing order, so a file's lines are contiguous and in line order, and a key's index order is line order within a file.

## Goals / Non-Goals

**Goals:**
- A bounded number of line checks per key, shown by a bench scenario over at least 148,091 lines.
- Rows spread across files with the counts in the title.
- No bidirectional format, zero-width, or separator character reaches the terminal from a row.

**Non-Goals:**
- Searching in the background or between keys (finder-streaming); a preview (finder-grep-preview).

## Decisions

- The matches of the last search are kept as their `Matcher.key` keys in index order (`@found`), with the number of stored lines checked so far (`@scanned`). The invariant: `@found` holds every line before `@scanned` that matches the current terms. A key's terms narrow the old ones when every old term is found inside some new term (`Matcher.find`, ASCII case ignored): a line holding every new term then holds every old one, so only `@found` needs checking again, and the scan continues at `@scanned`. Any other text (a backspace, a different word) starts at line 0.
- The bound: `LINE_BUDGET = 30_000` line checks. A fresh scan checks at most the budget; a narrowing checks every old match (at most the budget, by the invariant below) and then at most the budget less the matches it kept. So a search never keeps more than the budget of matches and never checks more than twice it. Counting the old matches against the fresh budget instead would stall: after `ab` kept 30,000 matches, `abc` would check them all and have no line left to scan, listing nothing while a match lay further on. Alternatives: a time budget would make the rows depend on the machine; a per-key cap with no narrowing would keep a long query at the first 30,000 lines for ever.
- At about 0.3 microseconds a line (45 ms for about 148,000 lines), a fresh key costs about 9 ms and the worst narrowing about 18 ms.
- The spread: the kept matches are cut into runs by file, each run sorted (at most 1000 keys, the run's best 200 kept, since a line ranked past 200 in its file is never shown), and the rows are filled round by round: round t takes the t-th best line of every file that has one, sorted by key, until 200 rows. Keys stay as `Matcher.key` builds them, so the order within a round and within a file (equal scores: the earlier line first) is the existing one. Packing the round into the key's high bits was rejected: a long query's score already uses the bits above the path and index rooms.
- The title is `Grep F of M files, L of N lines`: F is the files the rows show (every matching file when there are at most 200, since the first round takes one line of each), M and L carry `+` while `@scanned` is short of the stored lines, N carries `+` when the store cap cut the tree, as before.
- `safe` replaces U+202A to U+202E and U+2066 to U+2069, the review's code points, and, after the security review of this change, the marks U+061C, U+200E, and U+200F, the zero-width U+200B to U+200D and U+FEFF, and the separators U+2028 and U+2029 with a space in the multi-byte branch, by a private `format_control?`, as it does the C1 controls. `safe` and `utf8_size` become private instance methods.
- The bench `grep` scenario opens the picker in its setup (` fg`, the load not timed) over `GREP_FILES = 150` files of 1000 lines of the generated Ruby text, then types `count` and five backspaces: one fresh scan, four narrowings, four rescans, and one empty text per ten keys. `make bench-budget` runs it through `bench/run.sh` after the allocation check, at its default 100 keys for the time and at 20 and 120 keys for its allocations, since a grep key takes milliseconds, and prints its line, time per key included; no time budget fails it, since CI machines vary. The scenario exits with an error unless the picker's title shows every generated line and the lines of `a.rb` stored, so a changed read limit or listing cannot time an empty index.

## Risks / Trade-offs

- A short query on a tree past 30,000 lines lists only the matches of its first lines until the text grows more selective; the `+` on the counts says so, and finder-streaming will finish the scan between keys.
- A narrowing that keeps many matches (a trailing space, a query almost every line holds) adds no new lines that key; the counts keep their `+`.
