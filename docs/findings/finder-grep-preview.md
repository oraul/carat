### The quality first pass misses stale wording of a replaced behavior
- Location: .claude/agents/quality-reviewer.md (finder-match-strict retro note 13)
- Why: finder-match-strict's quality first pass listed no docs-currency advisory, then 3 later passes found 5 (the old 'fuzzy' or 'unchanged' wording in docs/plugins.md, docs/compatibility.md, docs/actions.md, docs/codebase-map.md, plugin.rb, README.md); quality first pass 106 of 194 overall; reviews 45,892 output tokens and 55 of 221 calls (25%); rework 2 of 3, round 2 docs-only.
- Fix: when a change replaces a behavior, the first pass searches the tree for the replaced behavior's old wording and reports every stale mention at once; accepted when such a change shows no docs-currency advisory after its first quality pass.

### An advisory-only round and the closing loop are two contributor starts for one kind of finding
- Location: .claude/workflows/deliver-change.js (finder-match-strict retro note 14); merge into `advisory-findings-auto` (backlog queue Pool 20)
- Why: after finder-match-strict's blocking fix, the fix-in-place round (3 docs advisories) and the closing loop (1 advisory closed, 1 left) each re-ran the check and the reviews (heads 752056e and 0409630) for 4 one-line doc edits; closing phases also in finder-grep (6,555/19), contributor-tier-routing (3,210/9), finder-grep-c (2,185/3), merged-record (1,194/2).
- Fix: advisories left after the last blocking fix get at most one contributor start and one re-check; accepted when a run with no blocking finding after round 1 shows at most one advisory start in its phases.

### The check-pass output budget line changed no decision
- Location: tools/run_state.sh, the check-pass budget line (finder-match-strict retro note 15); merge into `check-pass-budget-flag` (backlog queue Pool 19)
- Why: it printed over at 3 of 4 finder-match-strict check passes (256,092, 289,743, 307,646 of 200,000, notes 9, 10, 12) and the run went on unchanged; 8 of the last 9 medium feature rows exceed 200,000 output tokens (107,781 to 736,922) while 3 of 9 exceed the 1,200,000 total; this run 357,203 output, implement 185,448 (52%).
- Fix: calibrate the in-run output budget so it fires on at most 2 of the last 10 medium rows of a lane, or drop the check-pass line in favor of the total-token budget.

### The grep bench scenario now draws the preview float
- Location: bench/keys.rb (the `grep` scenario, 200 columns) and tools/metrics.sh compare
- Why: the scenario's terminal is wide, so every key now builds and draws the second float: at -O 0 `make bench-budget` read 644.6 allocations and 23.7 ms a key before and 842.6 allocations and 24.7 ms after (the preview's 18 lines, their host copies, and the float's render), so `metrics-compare` against a base recorded before this change reports more allocations for `grep`.
- Fix: re-record the base metrics for `grep` after the merge, or cut the per-key cost of a float refresh (reuse the preview window while the highlighted row and its file stay the same, update its lines in place); accepted when the grep scenario's allocations per key fall back to 645 or under with the preview shown.

### The grep preview ends at the last stored line, not the file's end
- Location: carat/plugins/finder/grep.rb, `Grep#preview`
- Why: the index keeps neither a file's length nor its empty lines and reads only the first 1000, so a window near a file's end stops at the last non-empty line within those 1000 and shows no line past them; the file finder's preview has no such limit when its file is short.
- Fix: have `read_file` (or a new host answer) report the file's line count and keep it per file in `Grep`, so the window clamps at the true last line; accepted when a file of 1200 lines previews lines up to 1200 around a hit at 1195.

### The file finder shows paths as the file lists them
- Location: carat/plugins/finder/plugin.rb, `list_lines` and the file finder's preview title in `refresh`
- Why: the grep rows and the grep preview's title show a path through `Grep#safe`, but the file finder's rows and preview title show the listed path as it is, so a file name with a control byte or a bidirectional override reaches the terminal there.
- Fix: pass the file finder's row text and preview title through the same safe-text path (make it a public `Finder` helper shared with `Grep`); accepted when a test lists a file named with a tab and an escape and shows spaces in the list and the title.

### File finder rows and preview title show the listed path unsanitized
- Location: carat/plugins/finder/plugin.rb:333 (the preview title and the rows, through selected_path)
- Why: the grep path now goes through Grep#safe, but the file finder still shows the listed path raw; in an untrusted repository a checked-in file name holding a bidirectional override (U+202E) or a zero-width character can make the finder show a different path than the one it opens. C0 controls are already shown as ^X by the frame presenter, so no escape sequence reaches the terminal. Security Low (confidence 5); the behavior predates this change.
- Fix: move Grep#safe into a shared helper in carat/plugins/finder/ and apply it to the file finder's rows and preview title wherever selected_path is shown, keeping the raw path for open_path; add a test with a path holding U+202E and a control byte.
### The quality first pass misses stale wording of a replaced behavior
- Location: .claude/agents/quality-reviewer.md (finder-match-strict retro note 13)
- Why: finder-match-strict's quality first pass listed no docs-currency advisory, then 3 later passes found 5 (the old 'fuzzy' or 'unchanged' wording in docs/plugins.md, docs/compatibility.md, docs/actions.md, docs/codebase-map.md, plugin.rb, README.md); quality first pass 106 of 194 overall; reviews 45,892 output tokens and 55 of 221 calls (25%); rework 2 of 3, round 2 docs-only.
- Fix: when a change replaces a behavior, the first pass searches the tree for the replaced behavior's old wording and reports every stale mention at once; accepted when such a change shows no docs-currency advisory after its first quality pass.

### An advisory-only round and the closing loop are two contributor starts for one kind of finding
- Location: .claude/workflows/deliver-change.js (finder-match-strict retro note 14); merge into `advisory-findings-auto` (backlog queue Pool 20)
- Why: after finder-match-strict's blocking fix, the fix-in-place round (3 docs advisories) and the closing loop (1 advisory closed, 1 left) each re-ran the check and the reviews (heads 752056e and 0409630) for 4 one-line doc edits; closing phases also in finder-grep (6,555/19), contributor-tier-routing (3,210/9), finder-grep-c (2,185/3), merged-record (1,194/2).
- Fix: advisories left after the last blocking fix get at most one contributor start and one re-check; accepted when a run with no blocking finding after round 1 shows at most one advisory start in its phases.

### The check-pass output budget line changed no decision
- Location: tools/run_state.sh, the check-pass budget line (finder-match-strict retro note 15); merge into `check-pass-budget-flag` (backlog queue Pool 19)
- Why: it printed over at 3 of 4 finder-match-strict check passes (256,092, 289,743, 307,646 of 200,000, notes 9, 10, 12) and the run went on unchanged; 8 of the last 9 medium feature rows exceed 200,000 output tokens (107,781 to 736,922) while 3 of 9 exceed the 1,200,000 total; this run 357,203 output, implement 185,448 (52%).
- Fix: calibrate the in-run output budget so it fires on at most 2 of the last 10 medium rows of a lane, or drop the check-pass line in favor of the total-token budget.
