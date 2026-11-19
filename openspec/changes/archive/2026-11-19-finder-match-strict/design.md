## Context

At f2c6f46 `Matcher.score` finds the leftmost in-order subsequence of the query in the file name, then in the whole path, tightens it from the end, and sums MATCH, BOUNDARY, and RUN points minus GAP per skipped byte, plus NAME_BONUS inside the name. It never rejects a match, only scores it low, and the plugin sorts `Matcher.key` keys (score, shorter path, listing index) of every path with a score of 0 or more.

## Goals / Non-Goals

**Goals:**
- No scattered match; contiguous and initials matches rank by a rule a user can predict.
- Nothing allocated per path; `key` and `index_of` unchanged.

**Non-Goals:**
- Changing the grep picker's substring rules, the preview, or the file listing.

## Decisions

- The score of a term is a small tier number: 7, 6, 5, 4 for a substring (file name at a word start, file name elsewhere, directory at a word start, elsewhere) and 3, 2, 1 for two, three, and four runs. A path's score is `worst * 256 + min(sum, 255)` over its terms, so the worst term decides the tier and the sum orders within it; every substring score is above every run score because the worst term decides. A query of no term scores 0, and `Plugin#filter` lists a blank query in listing order without sorting.
- Run matching is a depth-first search of at most four runs (`runs_match?`), tried for two, three, then four runs so the first success has the fewest. For one run length only the earliest start that matches is tried, since it leaves the most path for the rest, so the branching is by distinct run lengths, not by the number of starts: `a_a_a_...` with a long query costs one branch a level.
- Each term is a byte range of the query, so splitting at spaces allocates nothing; `find` becomes a call of `find_in` over such a range.
- ASCII case folding and byte comparison stay: a multi-byte character is matched by its bytes, a run after the first starts only at a `boundary?` byte (a lead or ASCII byte after a separator), so no run starts inside a character.

## Risks / Trade-offs

- The run search is exponential in the run limit in theory; with the limit of four and the earliest-start rule it is bounded by the distinct run lengths of the query, and the bench's allocations per key are held.
- A user who typed letters scattered across a path no longer finds it: that is the request.
