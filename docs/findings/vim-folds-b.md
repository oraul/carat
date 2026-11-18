### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)
- Location: `tools/run_state.sh` merge-main and plan-apply, `docs/queue-feature.md`.
- Why: after merge-main the delivery's own plan-apply edit of `docs/queue-feature.md` conflicted with the sprint-16-records rewrite; merge-main aborted, a contributor start redid the merge by hand, and the check, both reviews, and a second 16-minute CI ran again (merge 60,874 output tokens/21 calls against 24,917/7; ci_wait_calls 10 against 4 to 8).
- Fix: re-run plan-apply over the new main's queue in merge-main instead of merging the queue text, so a lane whose base predates a records merge takes in main with no conflict in `docs/queue-*.md` and no contributor start.

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)
- Location: `tools/run_state.sh` moved_change.
- Why: after the merge of main the moved check named `README.md` (merged cleanly, same diff against the new main) as changed and both reviews ran again, while the hand-merged `docs/queue-feature.md` was not named; reviews 37,844 output tokens/46 calls, 20 percent of the run's 227 calls, the rerun changing no decision.
- Fix: rerun the reviews exactly when the change's own diff of some file differs from its diff before the merge, a hand-resolved conflict file always counting; a tools-test case for each.

### Packaging writes advisory findings into the findings file by hand (tab-close-d retro)
- Location: `.claude/workflows/deliver-change.js` package phase, `docs/findings/<change>.md`.
- Why: packaging turned the run state's quality advisories into findings entries and a rewritten pull request text by hand in two docs-only commits, and the next quality review flagged the entries' format; package 60,830 output tokens/51 calls against a last-ten feature median of about 8,000/15.
- Fix: a `tools/run_state.sh` command appends the advisory notes to `docs/findings/<change>.md` in the file's one format; accepted when the next five medium runs' package phase stays near the median.

### The tab-close-d findings entries break the file's format (tab-close-d late finding)
- Location: `docs/findings/tab-close-d.md:11`.
- Why: the three entries added at packaging drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file.
- Fix: backtick the locations and end each Location, Why, and Fix line with a period, as above them.

### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.

### The benchmark phase starts an agent for a diff with no file under carat/ (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` benchmark phase.
- Why: with 0 carat files changed it builds base and change and reports every key unchanged: bench 3,547/6 in sprint-16-records, 4,178/8 in sprint-14-records, 3,467/7 in sprint-15-records, 11,192 output and 21 calls over 3 runs, 0 differences.
- Fix: record the bench phase without an agent start when no measured file changed; accepted when the next records row shows no bench share.

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)
- Location: `tools/run_state.sh` folded_backlog (`:2143`), groom.
- Why: the docs-lint hand edit of a removed findings path recurred in sprints 10, 12, 13, and 16; 2 of sprint-16-records' 6 quality advisories were fold defects already in the backlog (a third level-one heading, headings at `docs/backlog.md:7643`, `:7647`, `:7651` with no blank line).
- Fix: folded_backlog skips a findings file's leading `# ` line and separates every folded heading by one blank line; accepted when a records run ends with no hand edit after groom and no fold-format finding.

### Marked fold copies outlive a committed plugin edit
- Location: carat/domain/buffer.rb:640
- Why: the fold copies taken by transaction_mark are cleared only by revert_to, so after a successful plugin edit they stay, holding a closed window's Folds alive, and a later revert_to without a fresh mark, for example with transaction_size, restores stale folds, contrary to the risk note of the vim-folds-b design.
- Fix: clear marked_folds and marked_fold_copies in commit_transaction and on revert_to's early return, and add a test of revert_to after a committed marked edit.

### A revert test pins folds misaligned with their reverted lines
- Location: test/domain_edits.rb:221
- Why: the assertion 'a revert with no fresh mark puts back no old copy' pins folds [2,3],[4,5] against lines already reverted to six rows, enshrining folds misaligned with their lines as expected.
- Fix: assert only that no stale copy comes back (a fold count or a fold the stale copy would differ in), or shift the folds back in revert_to as the signs are.

### mark_folds copies every folded window's folds on each plugin edit
- Location: carat/domain/buffer.rb:794
- Why: mark_folds allocates a Folds copy per folded window on every plugin edit_buffer, success included, for a rollback only a failure uses.
- Fix: acceptable as designed, or take the copy lazily on the first splice of the marked transaction that touches a tracked fold list.

### A fold test label repeats keys instead of naming the behavior
- Location: test/editor_folds.rb:127
- Why: the label 'zf3jzozfj nests a fold at the outer fold's first row' repeats the keys of the drawing row at line 88 instead of naming the behavior it proves.
- Fix: label it by the state it proves, for example 'zf at an open fold's first row adds a closed fold nested in it'.
### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)
- Location: `tools/run_state.sh` merge-main and plan-apply, `docs/queue-feature.md`.
- Why: after merge-main the delivery's own plan-apply edit of `docs/queue-feature.md` conflicted with the sprint-16-records rewrite; merge-main aborted, a contributor start redid the merge by hand, and the check, both reviews, and a second 16-minute CI ran again (merge 60,874 output tokens/21 calls against 24,917/7; ci_wait_calls 10 against 4 to 8).
- Fix: re-run plan-apply over the new main's queue in merge-main instead of merging the queue text, so a lane whose base predates a records merge takes in main with no conflict in `docs/queue-*.md` and no contributor start.

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)
- Location: `tools/run_state.sh` moved_change.
- Why: after the merge of main the moved check named `README.md` (merged cleanly, same diff against the new main) as changed and both reviews ran again, while the hand-merged `docs/queue-feature.md` was not named; reviews 37,844 output tokens/46 calls, 20 percent of the run's 227 calls, the rerun changing no decision.
- Fix: rerun the reviews exactly when the change's own diff of some file differs from its diff before the merge, a hand-resolved conflict file always counting; a tools-test case for each.

### Packaging writes advisory findings into the findings file by hand (tab-close-d retro)
- Location: `.claude/workflows/deliver-change.js` package phase, `docs/findings/<change>.md`.
- Why: packaging turned the run state's quality advisories into findings entries and a rewritten pull request text by hand in two docs-only commits, and the next quality review flagged the entries' format; package 60,830 output tokens/51 calls against a last-ten feature median of about 8,000/15.
- Fix: a `tools/run_state.sh` command appends the advisory notes to `docs/findings/<change>.md` in the file's one format; accepted when the next five medium runs' package phase stays near the median.

### The tab-close-d findings entries break the file's format (tab-close-d late finding)
- Location: `docs/findings/tab-close-d.md:11`.
- Why: the three entries added at packaging drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file.
- Fix: backtick the locations and end each Location, Why, and Fix line with a period, as above them.

### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.

### The benchmark phase starts an agent for a diff with no file under carat/ (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` benchmark phase.
- Why: with 0 carat files changed it builds base and change and reports every key unchanged: bench 3,547/6 in sprint-16-records, 4,178/8 in sprint-14-records, 3,467/7 in sprint-15-records, 11,192 output and 21 calls over 3 runs, 0 differences.
- Fix: record the bench phase without an agent start when no measured file changed; accepted when the next records row shows no bench share.

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)
- Location: `tools/run_state.sh` folded_backlog (`:2143`), groom.
- Why: the docs-lint hand edit of a removed findings path recurred in sprints 10, 12, 13, and 16; 2 of sprint-16-records' 6 quality advisories were fold defects already in the backlog (a third level-one heading, headings at `docs/backlog.md:7643`, `:7647`, `:7651` with no blank line).
- Fix: folded_backlog skips a findings file's leading `# ` line and separates every folded heading by one blank line; accepted when a records run ends with no hand edit after groom and no fold-format finding.
