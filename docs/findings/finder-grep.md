### Advisory fixes take two paths and an advisory-only round counts as rework (closing-loop retro 10)
- Location: `.claude/workflows/deliver-change.js` (the in-place round, `inPlaceRound` 'alone', and the closing loop at package)
- Why: closing-loop rework 2 of 3, round 2 advisory-only (note 8, 0 blocking), its rerun (tools-test 135 s, every review again) raised note 9; reviews 43,866 of 191,898 output tokens (22.9%), 57 of 233 calls; quality first pass 101 of 183.
- Fix: keep one advisory path, so an advisory-only round is never a rework round and a run starts at most one contributor for advisories; accepted when a tools-test case shows a run with advisory-only reviews records rework unchanged and starts exactly one advisory start.

### Pull request finding counts are hand-written and checked after the push (closing-loop retro 11)
- Location: `tools/open_pr.sh` (the body gate before the first push)
- Why: two counts were wrong in closing-loop's body (Changes "two non-blocking advisories" against 5 entries, 4 distinct; Testing "one advisory"), costing a body round and a second push: prtext 5,495 output tokens / 11 calls, pr_text_fixes 1, pushes 2.
- Fix: refuse before the first push a body whose finding counts differ from the run state's reviews or the findings file, or keep counts out of the body; accepted when the next runs record no prtext phase from a count.
### Grep picker reads every file synchronously when it opens
- Location: carat/plugins/finder/grep.rb, Grep#load
- Why: a large tree makes the editor wait once at open (one read_file call per file, up to 100,000 stored lines); the user's nothing-waits rule is only met by bounding it.
- Fix: stream the read as a background task once finder-streaming and plugin-tasks land after spinel-bump, searching what has arrived.
### Grep column is the first query byte, not the tightened match start
- Location: carat/plugins/finder/grep.rb, Grep#column_at
- Why: Matcher tightens the match from its end, so the highlighted span can start later than the first occurrence of the query's first byte; the cursor then lands a little early on such lines.
- Fix: expose the span start from Matcher.span_score (a second method, no extra allocation) and use it for the column.
### Grep files are searched only to their first 1000 lines
- Location: carat/plugins/finder/grep.rb, FILE_ROWS
- Why: read_file answers at most 1000 rows, so a match deeper in a long file is not found.
- Fix: a read request with a start row, a plugin API minor bump, then read the file in pages.
