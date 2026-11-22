# Backlog: .claude/workflows/deliver-change.js

## /status and a killed run lose the package, CI, and merge phases

- Where: `.claude/workflows/deliver-change.js` lines 608 to 625, which leave the package, CI, and merge phase lines to the closing start, and the next-phase loop of `show_status` in `tools/run_state.sh` (line 489). Advisory of the quality review of `workflow-records`.
- Why it matters: during the CI wait `/status` prints next phase package although the pull request is open, and a run killed between the merge and the closing start never records package, ci, and merge, so its history row lacks those phases.
- Fix outline: have `status` read `pushed`, `pr`, and `merged` as the resume does when the phase lines are absent, or record each phase as soon as its own record exists; add a `tools/tools_test.sh` case for a run state with `pushed` and `pr` but no package line. Queued in `run-resume`.
- Also: tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## A resumed run can be granted an extra fix round after stopping at the limit

- Where: `stopKind` in `.claude/workflows/deliver-change.js` (line 67), which starts at `none` on every start. Quality advisory of `pipeline-speed` at 1d187291be30.
- Why it matters: the checker's metric line (`figuresFirst`) overwrites a stored `stop=rounds` with `none` before `mayFix` runs, so a start killed after that check makes the next resume grant an extra round to a run that had stopped at the round limit.
- Fix outline: seed `stopKind` from `lastStop` when `rework` is already at `ROUNDS` plus `extra`. Queued in `run-resume`.
- Category: pipeline
- Added: 2026-11-04

## The merge-gates worktree is never removed

- Where: the merge-gates worktree command in `.claude/workflows/deliver-change.js` (about line 476, beside `MERGE_GATES` at line 455), which now prunes first, and step 8 of `.claude/agents/merger.md`. Periodic quality advisory at e20c83c, again at 7711421 (note 23).
- Why it matters: the command removes `tmp/.merge-gates` before adding it but nothing removes it after the merge, so the first run prints a git error into the gate output the merger reads and every later run finds a stale worktree.
- Fix outline: send the remove's error to `/dev/null` and remove the worktree after the merge. Queued in `merge-gate-tidy`.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-04

## A fix review is never scoped for a finding in a dot directory

- Where: `.claude/workflows/deliver-change.js` line 312 and the scope path check of `tools/run_state.sh` line 349. Periodic quality advisory at e20c83c.
- Why it matters: both patterns refuse a leading dot, so a blocking finding in `.claude/` or `.github/`, the files pipeline changes edit, always sends the next quality review to the whole branch.
- Fix outline: admit a leading-dot segment other than `..` in both patterns, keeping the parent-step check, with a `tools/tools_test.sh` scope case for an agent file under `.claude/agents/`. Queued in `implement-contracts`.
- Also: tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## CI failures are not classified before a fix round

- Where: the CI step of `.claude/workflows/deliver-change.js` and the merger's brief under `.claude/agents/`, where a red CI goes back to the contributor as a fix round whatever its cause. From the user's insights review in the brief of `pipeline-speed-c`.
- Why it matters: a flaky test or an infrastructure failure (a runner, a cache, a network fetch) would cost a contributor round and a push of the one-push budget for a commit that changes nothing. Low value now: CI passed first in 17 of 17 recorded runs, so no round has been lost to it yet.
- Fix outline: have the CI result name its class (flaky, infrastructure, or code) from the failing step and log, retry the first two once without a fix round or a push, and count only a code failure as rework, with a `tools/tools_test.sh` case per class. Queue it when a CI first pass fails for a cause other than code.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## A closing start that returns no result stops the run without a reason

- Where: `.claude/workflows/deliver-change.js` line 686, after the closing start. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: the old code stopped with 'the retrospective returned no result'; now a merged run whose closing start returns nothing returns 'No report' with no reason, and a due periodic review is skipped silently.
- Fix outline: when `close` is null, set `stopped` to 'the closing start returned no result' and keep the resume rerunning that start. Queued in `run-resume`.
- Category: pipeline
- Added: 2026-11-04

## The closing fallback can record a note twice

- Where: `.claude/workflows/deliver-change.js` line 695, the fallback flush after a closing start that did not record, and `add_note` in `tools/run_state.sh`, which dedupes only `quality-advisory` notes. Quality advisory at e8c5b43 in `pipeline-speed-c`. Raised again at ce6abdb (`tools/run_state.sh:1103`; periodic quality): a restarted periodic start records its findings twice; the same bare-text comparison for the quality and security kinds, queue item `run-budgets-tidy`.
- Why it matters: when the closing start ran part of the record line before a later command failed, the fallback reruns every line, so an extra-round note is recorded twice and the history counts it twice.
- Fix outline: dedupe identical notes of every kind in `add_note`, or push back only the lines after the one that failed, with a `tools/tools_test.sh` case of a note recorded twice. Queued in `run-resume`.
- Also: tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The closing phases are listed twice with no pointer between them

- Where: `CLOSABLE` in `.claude/workflows/deliver-change.js` line 266 and `CLOSE_PHASES` in `tools/agent_guard.sh` line 92. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: a phase added to one list and not the other is refused by the guard or misrouted by the workflow.
- Fix outline: name `tools/agent_guard.sh` `CLOSE_PHASES` in the comment above `CLOSABLE`, and the workflow's regex in the comment beside `CLOSE_PHASES`. Queued in `run-resume`.
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-04

## The checker reports a check's outcome both as passed and as a verdict

- Where: `.claude/workflows/deliver-change.js` line 107 (the `CHECK` schema still requires `passed` and offers `failed_stage`, which `rounds()` no longer reads) and step 5 of `.claude/agents/checker.md`. Quality advisory of `pipeline-durability`.
- Why it matters: one fact reported two ways can disagree, and the workflow routes only by the verdict.
- Fix outline: drop `failed_stage` and `passed` from `CHECK` and checker step 5's passed-or-not, keeping `verdict` as the one answer.
- Also: .claude/agents/checker.md
- Category: pipeline
- Added: 2026-11-05

## The close note names the backup when there was none

- Where: `.claude/workflows/deliver-change.js` line 718 (the close note says the backup stays on origin whenever a run stops unmerged, even after the push deleted it or when no backup was made). Quality advisory of `backup-secret-scan`.
- Why it matters: the report sends the user to `abandon` a backup that does not exist.
- Fix outline: also require `state.backup`, the record `backup_branch` writes and `drop_backup` drops. Queued in `backup-records`.
- Category: pipeline
- Added: 2026-11-05

## A refused backup push is retried and protects nothing here

- Where: the backup step of `.claude/workflows/deliver-change.js` and `backup` in `tools/run_state.sh`; this environment's git proxy refuses a push to `refs/backup/` with HTTP 403. Retrospective proposal of `backup-secret-scan`, recorded here by the user's decision rather than queued.
- Why it matters: in `backup-secret-scan` 2 of 2 backup pushes were refused and 0 backup refs reached origin, so the step spent tokens and changed no decision, and the run state holds no backup record to tell the report so; `docs-currency` made 7 more attempts, and 0 of 9 across the two runs reached origin (its retrospective); in `buffer-list` the implement and fix pushes all failed, 0 `refs/backup` refs reached origin, and 7 commits stayed local until the package push (retrospective note 11); in `leader-layout` 2 of 2 backup tries were refused (retrospective note 8), so no backup has reached origin in four runs; in `lsp-diagnostics` 8 attempts over 3 contributor starts were refused and no `refs/backup` ref reached origin (retrospective note 18), and in `diagnostics-display` all 6 implement commits and 3 more tries were refused, no restore being used; the first backup of `partial-results` was refused the same way; in `check-isolation` 3 of 3 backup pushes were refused, and 7 runs' retrospectives have recorded the same proposal. Kept here by the user's earlier decision, which the user may want to revisit; queued in `backup-records`.
- Fix outline: record a refused backup push once in the run state, make no later backup attempt in that run, and have the report say no backup exists, with a `tools/tools_test.sh` case for a refused push.
- Raised again at 6a0db20 (periodic quality, note 19).
- Also: tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-05

## Three places repeat the estimate test of sizeWord

- Where: `capLine` (line 96 at `run-budgets`) and `overCap` (line 220) in `.claude/workflows/deliver-change.js` repeat the `SIZES.includes(estimate)` test beside `sizeWord` (line 94). Quality advisory of `run-budgets`.
- Why it matters: three copies of one validity test drift when the sizes change.
- Fix outline: one `hasEstimate` helper used by all three.
- Category: pipeline
- Added: 2026-11-06

## The workflows repeat the commit pattern

- Where: `.claude/workflows/deliver-change.js` repeats the `COMMIT` pattern (line 368 at 594dd35) inline in `pushedHead` (line 248) and in the head check of a capped start (line 496); `.claude/workflows/periodic-review.js` repeats its `isCommit` (line 58) in `areasLeft` (line 74) and computes `areaSlices(MAP_AREAS, QUALITY_SLICES)` twice (lines 103 and 117). Quality advisories in `partial-results`. At 38628bb `.claude/workflows/periodic-review.js` line 74 still repeats it (periodic quality).
- Why it matters: a change to the accepted commit form or to the slicing has to be made in each copy, and nothing fails when one is missed.
- Fix outline: define `COMMIT` above the helpers and use `COMMIT.test` in both places, use `isCommit` in `areasLeft`, keep the slices in one const, and add `COMMIT` and `isCommit` to the js helper names in `tools/tools_test.sh`.
- Also: .claude/workflows/periodic-review.js, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-07

## A continued fix-round quality review is told to review the whole diff

- Where: `qualityReview` in `.claude/workflows/deliver-change.js` (line 581 at 594dd35) uses `more || scope`, so the continuation replaces the prior-review scope; the sentinel `the whole diff` is produced by `reviewLeft` (line 228) and compared in `reviewMore` (line 592). Quality advisories in `partial-results`.
- Why it matters: a capped or empty fix-round quality review is continued over the whole committed diff instead of the fix diff, spending review tokens the `review-scope` item is meant to save, and the sentinel string has two owners.
- Fix outline: append `more` to `scope` and say the files left are of that scope; name the sentinel once as a constant, or have `reviewLeft` signal a whole-diff rerun separately.
- Category: pipeline
- Added: 2026-11-07

## The CALL_CAPS comment has a short line

- Where: the comment above `CALL_CAPS` in `.claude/workflows/deliver-change.js` (line 89 at 594dd35) leaves the short line `// margin), so a start` before the paragraph continues. Quality advisory in `partial-results`.
- Why it matters: the comment reads as broken and differs from the file's width.
- Fix outline: rewrap the comment to the file's width.
- Category: pipeline
- Added: 2026-11-07

## The close start's calibration profile is never recorded

- Where: `.claude/workflows/deliver-change.js` line 924, where `records` takes `metricLine()`, before `calibrate('close', ...)` runs at line 928. Quality advisory in `agent-calibration` (reported at lines 915 and 924 across its rounds).
- Why it matters: the close start's line is the run's last metric line, so `metric.calib.close` never reaches the run state or the history's calibration column, unlike the design's profile recorded for every kind started; the close start's tier and effort cannot be compared against its outcome.
- Fix outline: build the close start's options with `calibrate('close', ...)` before computing `records`, and pass the built options to `agent`, with a `tools/tools_test.sh` case that the close profile is in the record line.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-07

## The merge record trusts the merger's reply fields

- Where: the merge and CI phase records of `.claude/workflows/deliver-change.js`; in `parameter-info` (#78) the reply swapped the pushed head and the squash commit, so 3 phases were recorded at a commit not on main (retrospective). Queued in `merge-gate-tidy`. Raised again at 9a92265 (#99 retro note 6).
- Why it matters: run state and history rows point at the wrong commits, 1 of the last 4 merges.
- Fix outline: take each commit from the run state or git (the squash commit reachable from main, the CI head equal to the pushed head), with a tools_test case feeding a swapped reply.
- Category: pipeline
- Added: 2026-11-09

## The planner's backlog text reaches the package unchecked

- Where: the package step of `.claude/workflows/deliver-change.js` copies the planner's backlog text before `make docs-lint` sees it; retrospective of `feedback` (#83). Queue item `phase-shares`.
- Why it matters: one entry named a missing path, failing `docs-lint` and costing the package a separate fix commit.
- Fix outline: check the planner's output for missing paths before the package copies it, with a case in `make tools-test`.
- Category: pipeline
- Added: 2026-11-09

## A resume of finished tasks reruns plan and scouts and grants a fourth round

- Where: `.claude/workflows/deliver-change.js`, the resume and round limit. Retrospective, `extra-round`, and `overrun` notes of `definitions`, queued in `run-resume`.
- Why it matters: `definitions` resumed at 73baf73 with 6 of 6 tasks done, spent 117,076 of 474,458 output tokens (24.7%) on plan and scouts, and was granted round 4, which took output from 389,765 to 436,791, past the large budget of 416,666.
- Fix outline: decide which phases a resume repeats (a done, unchanged branch starts at check) and count rounds across starts, stopping at 3, with cases.
- Category: pipeline
- Added: 2026-11-10

## The record phase is a separate agent start

- Where: the record start of `.claude/workflows/deliver-change.js`; retrospective note 7 of `jump-list`.
- Why it matters: it runs one queued shell line for 641 to 1,170 output tokens and 1 or 2 calls in each of the last 10 rows, while the close start already runs a record line of the same kind.
- Fix outline: none prescribed; accepted when 3 runs have no record phase and `show` lists the same keys. Queue item `phase-shares`.
- Category: pipeline
- Added: 2026-11-10

## A superseded red CI is handled as a real red

- Where: the merger's CI handling in `.claude/workflows/deliver-change.js`; retrospective note 11 of `url-email-guard`.
- Why it matters: #100's first text job failed on a footer removed 12 s later and its rerun passed, yet the run spent a contributor start with no commit and a full review round (reviews 37.7% of output).
- Fix outline: none prescribed; accepted when a stale red resolves without a contributor start or a rework count, in a case. Queue item `merge-gate-tidy`.
- Category: pipeline
- Added: 2026-11-11

## A re-review rereads commits that touch no reviewed code

- Where: the review rounds of `.claude/workflows/deliver-change.js`; retrospective note 12 of `url-email-guard`.
- Why it matters: #100's second round reviewed only packaging commits and re-rated an unchanged Medium (7) to (8), a round of rework.
- Fix outline: none prescribed; accepted when over 5 runs no round comes from a re-rating on unchanged lines. Queue item `review-scope`.
- Category: security
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:796

- Where: `.claude/workflows/deliver-change.js:796`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: reRaised matches file:line only, so a new correctness bug a fix round introduces at the line of an earlier advisory is silently demoted.
- Fix outline: demote only when the blocking text without its commit equals the earlier advisory's text, or also compare the reason.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:97

- Where: `.claude/workflows/deliver-change.js:97`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the CALL_CAPS comment still says a capped start can commit, back up, and return the schema.
- Fix outline: drop back up.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:344

- Where: `.claude/workflows/deliver-change.js:344`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: settledRecords repeats the commit pattern /^[0-9a-f]{7,40}$/ that COMMIT already holds.
- Fix outline: use COMMIT.test.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:795

- Where: `.claude/workflows/deliver-change.js:795`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: reRaised demotes any blocking quality finding whose file:line equals an earlier advisory, by location alone, in any round and whatever the finding says, so a new correctness bug on a line that once carried a style advisory merges with only a note, and line numbers shift between commits.
- Fix outline: demote only in a narrowed fix round and compare the finding text as well as file:line.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1089

- Where: `.claude/workflows/deliver-change.js:1089`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: a closing start that does not record now loses its phase lines and metric line with only a note, so a merged run history row can lack its package, ci, and merge figures.
- Fix outline: keep one record start for the refused close, or say in the report which figures are missing.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:481

- Where: `.claude/workflows/deliver-change.js:481`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: dead code: 'if (!command) return true' cannot run, since flush returns earlier unless a non-closable line is pending.
- Fix outline: drop it.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1015

- Where: `.claude/workflows/deliver-change.js:1015`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: a superseded red reuses the pending wait counter, so the merger's next prompt says CI was still running, and the body mode is measured under the package key (line 610).
- Fix outline: a separate counter and prompt for a superseded red, and its own usage key for body.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1073

- Where: `.claude/workflows/deliver-change.js:1073`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: on a resume past the push the reviews rerun over the whole diff with an empty handed set, so recordLate at the close turns every advisory the package step already appended into late-finding notes that history appends to docs/backlog.md again.
- Fix outline: record late findings only from a start that ran the package step or a CI fix, or dedupe against the backlog text in append_history.
- Category: pipeline
- Added: 2026-11-11

### ci-stages queued on every green or red return (`ci-time` quality advisory)

- Location: `.claude/workflows/deliver-change.js:1029`.
- Why it matters: ci-stages is queued on every green or red return, the stale reds that loop again included, so the same line can run several times.
- Fix outline: queue it beside verdict('ci', ...) after the stale-red and pending checks.
- Category: pipeline
- Added: 2026-11-11

### staleRed trusts the merger's order of check runs (`delivery-speed` quality advisory)

- Location: `.claude/workflows/deliver-change.js:301` (`staleRed`) and `.claude/agents/merger.md:24`. Re-entered by the sprint-1 grooming from the second copy of the repeated heading at that line, whose first copy (a comma inside a check name) stays.
- Why it matters: staleRed relies on the merger listing check runs oldest first while GitHub lists them newest first; a misordered list starts a needless fix round or asks again up to WAITS times.
- Fix outline: have the merger return only the latest run per name, or a completion time to sort on, with a tools-test case for each order.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-12

### The merge phase names the branch head, not the squash commit (`ci-time` retrospective)

- Location: the closing input of `.claude/workflows/deliver-change.js` and the `phase.merge` line it records.
- Why it matters: #110 passed the branch head 2e6c64184f00 as merged while the squash on main is 8df063e271c8, so `phase.merge` and the closing gates' BASE name the head; `phase.merge` differs from `merged` in 11 of 74 run states.
- Fix outline: the closing input, `phase.merge`, and `merged` all name the commit on origin/main's first-parent line, with a tools-test case where the merger returns the head. Queue item `merge-gate-integrity`.
- Category: pipeline
- Added: 2026-11-12

### A delivery whose item heads the queue still plans the whole pool (`ci-time` retrospective)

- Location: the plan phase of `.claude/workflows/deliver-change.js` and `plan-needed` in `tools/run_state.sh`.
- Why it matters: #110's item was already decided and estimated, yet 7 of the plan's 8 decisions were about other items: plan 29,632 of 176,620 output tokens (16.8%), plan plus scouts 28.4% at rework 0; plan 4.5% to 23.3% of output over the last 10 rows.
- Fix outline: a delivery whose item heads the queue with an estimate starts no planner, or plan stays under 5% of output over three runs. Queue item `sprint-tidy`.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-12

## records-once quality advisory at .claude/workflows/deliver-change.js:999

- Location: .claude/workflows/deliver-change.js:999, against tools/rules.sh:52 (RECORDS_RE) and the README.
- Why: the planning records means two sets: RECORDS_RE and the README count the queue and goals among them, while records=skip excludes only history and groom and the package step still applies the planner queue.
- Fix outline: say history and groom (or the metrics and sprint rows) wherever records=skip is described, in the workflow text, the run_state.sh header, CLAUDE.md, and the README.
- Also: tools/rules.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-12

## records-once quality advisory at .claude/workflows/deliver-change.js:961

- Location: .claude/workflows/deliver-change.js:961 and tools/tools_test.sh.
- Why: excludeRecords and the package text it selects have no js case in tools/tools_test.sh; only the run_state.sh side is tested.
- Fix outline: move the package-text choice into a pure helper and add a js case for records skip and apply.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-12

### Read the scan red right after a body push as pending (quality advisory)

- Where: `.claude/workflows/deliver-change.js:1094` and `.claude/workflows/deliver-change.js:1102`
- Why it matters: after the body push the merger can read the synchronize scan red before open-pr edits the text and reruns scan (spin skips a records-only diff, so checks finish fast); with bodyFixed set that red becomes a fix round.
- Fix outline: have body mode poll until the pull request text equals pr.md, or read a body-only red right after a body fix as pending once.
- Category: pipeline
- Added: 2026-11-14

### One settlePackage helper for the wait and package branches (quality advisory)

- Where: `.claude/workflows/deliver-change.js:1018`
- Why it matters: the wait and package branches repeat the same pr, stop, and phaseDone tail, and the step is named merge when the run already stopped.
- Fix outline: one `settlePackage(done)` helper for both branches and a skip step word for a stopped run.
- Category: pipeline
- Added: 2026-11-14

### The body-fix path can read a stale scan run

- Location: .claude/workflows/deliver-change.js:1102 (sprint-4 review, quality).
- Why: the body mode pushes pr.md as a CI fix whose scan run reads the old body and goes red before open-pr edits the body, so a merger reading checks in that window returns red with bodyFixed true and the run falls into a fix round.
- Fix: wait until the open pull request's title and body equal pr.md's before returning, or have the merger ignore a scan run older than the last edit.
- Category: pipeline
- Added: 2026-11-14

### The wait and package blocks repeat three lines

- Location: .claude/workflows/deliver-change.js:1015 (lines 1018-1020 and 1030-1032; sprint-4 review, quality).
- Why: packagedPr, the no pull request stop, and phaseDone package are written twice.
- Fix: one helper taking the contributor result.
- Category: pipeline
- Added: 2026-11-14

## Quality: the merger's hook refuses guard-pin-no-url's own green line until the guard lands

- Location: `.claude/workflows/deliver-change.js:551` (the green line now runs `git hash-object --stdin`) and `tools/agent_guard.sh:549` (the merger's `git hash-object --stdin` allowance, which lands on main only with guard-pin-no-url).
- Why it matters: quality advisory. The merger's hook runs origin main's guard, which refuses `git hash-object`, so the merger's hook refuses guard-pin-no-url's own green line and the run cannot merge it; the design names this bootstrap risk without a plan, and any later change that widens what the green line runs meets the same ordering problem.
- Fix outline: land a green-line command's guard allowance in its own change before the change that runs it, or state in that change's `pr.md` Notes that its one merge is done by the user; for guard-pin-no-url the merge is the user's.
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-15

### The origin pin is checked two ways in the hooks and the green line

- Location: `.claude/workflows/deliver-change.js:542` (`originCheck`) against the hook lines under `.claude/agents/` (sprint-5 quality review).
- Why it matters: the hooks hash `config --local remote.origin.url` with `.git` stripped against 3 ids, while `originCheck` hashes `remote get-url` against 6 ids (the 3 plus their `.git` forms), so the recipe and the id list live in two shapes in 11 places.
- Fix outline: strip a trailing `.git` in `originCheck` too, keep only the three ids, and say in the `tools/agent_guard.sh` header that both read the address the same way. Queue item `hook-one-place`.
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-15

## The resume brief misses the planner's queue when the planner runs

- Location: .claude/workflows/deliver-change.js:967
- Why: resumeBrief is computed from plan-needed's line before the planner runs; on 'needed: c is not the head of docs/queue.md' the planner writes build/plan/queue.md, yet a change-name-only brief now names docs/queue.md alone (the old one named both), so an item the planner adds or rewrites there is missed.
- Fix: name build/plan/queue.md as well when the planner runs, or build the brief after the plan phase.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

### scoutPrompt joins blank locations

- Location: .claude/workflows/deliver-change.js:184
- Why: scoutPrompt joins every location, blank ones included, while scoutTargets keeps an area for one non-blank location, so a prompt can read 'Locations: , x'.
- Fix: have scoutTargets return the areas with their trimmed non-blank locations and join those.
- Category: pipeline
- Added: 2026-11-16

### PACK_CURRENT and scout.md step 3 apply different currency rules

- Location: .claude/workflows/deliver-change.js:176
- Why: the comment says scout.md step 3 applies the same rule as PACK_CURRENT, but step 3 (.claude/agents/scout.md:35) also requires the same question while PACK_CURRENT ignores it, so the plan reuses a pack the scout itself would not.
- Fix: drop 'and question' from step 3 or add the question to PACK_CURRENT, keeping one rule.
- Also: .claude/agents/scout.md
- Category: pipeline
- Added: 2026-11-16

### The close start returned a placeholder with no tool calls
- Location: .claude/workflows/deliver-change.js, the close (retrospective) start of markdown-reading-a (#146), run state notes 8 and 9
- Why: twice in one run the retrospective start returned a placeholder after no tool calls, so the main session ran its record line by hand and corrected the merger's squash commit (67562e699059 stored for 67562e69905c); the run's last records depend on that start
- Fix: refuse a close result made with no tool calls and restart it once, or record the run's last lines without the model; accepted when a stubbed placeholder close is refused by a case and the record line still lands
- Category: pipeline
- Added: 2026-11-16

### A resume past the push cannot answer a new blocking review
- Location: .claude/workflows/deliver-change.js resume past the push (the blocked-on-resume stop) and tools/run_state.sh push
- Why: twice (review-coverage, backlog-lane-a) a resumed quality review raised new blocking findings at the pushed head and the run could only stop, costing a redelivery
- Fix: let a resume past the push run one fix round whose push counts as a review fix, or demote a resumed review to the findings the last pass did not already settle
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-16

### MERGE_MAIN tells a continuation start to merge over a dirty tree
- Location: .claude/workflows/deliver-change.js:702, tools/run_state.sh:2385
- Why: correctness: every implement and fix start is told to run merge-main first, but merge_main dies on a dirty tracked tree, so a continuation over uncommitted work exits 1 before it starts.
- Fix: say to run it when the tracked tree is clean, else after the next commit.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### The one review fix round a run counts only pushed rounds
- Location: .claude/workflows/deliver-change.js:966 and 978 (resumeFix), tools/run_state.sh push (writes review_fixes)
- Why: review_fixes is written only by the push, so a round that began and stopped unpushed lets a later start begin another, against the proposal's rule that a second round, in the same start or a later one, is refused.
- Fix: Record the round in the run state when it begins (a review_fix_round key) and count it in resumeFix.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### The review fix push result is ignored
- Location: .claude/workflows/deliver-change.js:1156 and 1172
- Why: The result of the review fix contributor('push') is not checked, so a refused or failed push surfaces only as the pushedHead mismatch stop and its reason is lost.
- Fix: If the push start returns false, keep the stop the contributor set or set stopped with the push's reason, as the CI fix path at line 1217 breaks.
- Category: pipeline
- Added: 2026-11-17

### A review fix round turns off review narrowing for the rest of the start
- Location: .claude/workflows/deliver-change.js:798 (priorSecurity)
- Why: Performance: once reviewFixRounds is above zero, every later CI fix round after the review fix push re-reviews the whole branch diff, costing tokens and time.
- Fix: Drop narrowing only for the review fix round's own reviews, for example remember the head the round began at and narrow from passes after it.
- Category: pipeline
- Added: 2026-11-17

### A resume pushes an unpushed CI fix as the review fix
- Location: .claude/workflows/deliver-change.js:909 (resumePush)
- Why: resumePush pushes any head past the recorded push as the review fix, so an unpushed CI fix commit, from a start stopped between the CI fix commit and its --ci-fix push, is pushed with --review-fix: ci_fixes is not counted and the run's one review fix is spent, so a later blocking review on resume is refused.
- Fix: Push with --ci-fix when CI is recorded red and keep --review-fix for a blocked review only, or name the case in the comment and the README.
- Category: pipeline
- Added: 2026-11-17

### SELF_CHECK repeats the contributor's implement step 5
- Location: .claude/workflows/deliver-change.js:684 (SELF_CHECK), .claude/agents/contributor.md implement step 5
- Why: Every implement and fix prompt carries the same rule twice, and the two texts can drift apart.
- Fix: Keep the rule in the agent file and have the prompt point to step 5, or drop step 5's copy.
- Also: .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-17

### A change touching no carat/, bench/, or test/ file still runs the benchmark phase
- Location: .claude/workflows/deliver-change.js, the benchmark phase (sprint-10-records retro note 4)
- Why: the records-only sprint-10-records spent 4,848 output tokens and 6 calls on the benchmark (9.3% of 52,240 output tokens, 7% of 86 calls) plus a base and a change build, while its check scoped the metrics stage out; bench first pass 117 of 118 over the history, allocations and rounds unchanged on every key.
- Fix: skip the benchmark phase, recording the skip, when the committed diff touches no file under carat/, bench/, test/, or the Makefile; accepted when the next records change shows a recorded skip and no skipped change later shows an allocation or rounds difference.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-17

### A phase's recorded output differs from its agent starts' output
- Location: `.claude/workflows/deliver-change.js` phase accounting, `metric.phases` (markdown-reading-c retro note 18).
- Why: phase.check recorded 150,693 output and 27 calls (37.9% of 397,894) while its three checker starts summed 5,213; git-signs-status-b check 57,747 and checks-and-pr-lows 38,907 against 2,029 to 6,432 earlier, so `check-skip` and share-based proposals judge a number the checker did not spend.
- Fix: accepted when, for the next three runs, each phase's recorded output is within 10% of the summed output of its agent starts.
- Category: pipeline
- Added: 2026-11-17

### A merge refused on a moved main costs a full resume and a CI failure
- Location: `.claude/workflows/deliver-change.js` merge and resume path (markdown-reading-c retro note 20).
- Why: CI green at the first push in 7 min, yet first.ci 0; merge 39,463 output in 24 calls (ci_wait_calls 10), and the resume re-ran 3 checker, 3 quality, 3 security starts.
- Fix: accepted when the next merge refused for a moved main records first.ci 1 on a green CI and reaches the merge with no new checker or review start unless merging main changed files under carat/ or tools/.
- Category: pipeline
- Added: 2026-11-17

### The merge start passes its cap on a first-pass green CI
- Location: merger start, `CALL_CAPS` in `.claude/workflows/deliver-change.js`; pool item `merge-gate-integrity` (planner-split-rule retro note 7).
- Why: merge 18,979 output in 14 calls (13.2%) with first.ci 1; 5 of the last 8 medium backlog rows at 14 calls against a cap of 12; merge output 17,462 to 30,050 in 4 runs against 4,045 to 6,438 in 9 of the last 10 feature rows.
- Fix: fold into `merge-gate-integrity`; accepted when five medium runs in a row merge within cap, no overrun note, under 6,000 output on a first-pass green CI.
- Category: pipeline
- Added: 2026-11-17

### A check pass after a fix round costs more than a first pass
- Location: `.claude/workflows/deliver-change.js` check phase; backlog pool item `check-skip` (git-signs-status-b retro note 9).
- Why: git-signs-status-b's check took 57,747 output tokens in 11 calls (16.8% of 342,779) over 2 passes that both passed; the last 20 lane rows ran 1,970 to 24,171; check first pass 121/123.
- Fix: fold into `check-skip`; accepted when the next three feature runs keep check at or under 6,000 output tokens per pass with first.check still 1.
- Category: pipeline
- Added: 2026-11-17

### A resumed run records 0 output tokens for the phases done before the resume
- Location: `.claude/workflows/deliver-change.js` resume path, `metric.phases` and the history row (git-signs-status-b retro note 10).
- Why: git-signs-status-b recorded plan=0/10, areas=0/2, scout=0/14 against plan 10,124 to 25,457 and scout 18,002 to 64,257 output in the last 10 feature rows, so its output total and the check-pass budget line undercount.
- Fix: accepted when a resumed run's carried phases show their recorded tokens or are marked carried in the phases and the history row, never 0 beside non-zero calls.
- Category: pipeline
- Added: 2026-11-17

### The workflow trusts an agent-reported head without git
- Location: .claude/workflows/deliver-change.js:776
- Why: a fabricated sha sharing a 7-character prefix stopped a passing run at check and made record lines fail.
- Fix: resolve each reported head with git rev-parse in the lane and stop on a mismatch.
- Category: pipeline
- Added: 2026-11-17

### The checker's start costs as much as a fix round on a first-pass check
- Location: the check phase of `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md` (palette-narrow note 4).
- Why: palette-narrow's check took 40,656 of 304,750 output tokens (13.3%) in 8 calls for a pass at the first try, while check first pass is 130 of 132 changes and 6 of the last 10 feature rows' check phase ran under 6,200.
- Fix: remove or merge the checker start so a passing check costs little; accepted when a first-pass check costs under 6,000 output tokens in 4 of the next 5 runs and a failing stage still returns to the contributor.
- Also: .claude/agents/checker.md
- Category: pipeline
- Added: 2026-11-17

### The check-pass budget step returns nothing or reads under (same proposal as budget-prediction)
- Location: the check-pass budget step of `.claude/workflows/deliver-change.js` (palette-narrow note 4, check-parallel note 9).
- Why: check-parallel's step printed no spent line; palette-narrow's read under at 178,345 because it counted no phase from check on, which then added 126,405 (41%); the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: drop the step or fold it into the close budget line; accepted when over the next 5 runs every budget step prints an under: or over: line, or the close line is the only one.
- Category: pipeline
- Added: 2026-11-17

### A post-review prose edit in the package step refuses the push
- Location: the package step of `.claude/workflows/deliver-change.js` and the check and security records it invalidates
- Why: in lsp-container-b a docs-only wording fix (`docs/architecture.md:275`, Open3) invalidated the recorded check and security review, the push was refused, the edit reverted and the stale sentence left on main; package 21 of 210 tool calls (10.0%) (retro note 12).
- Fix: settle the advisories the package step may fix before the last review, or let pure prose edits of docs keep the records; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit. Queued in `check-skip`.
- Also: docs/architecture.md
- Category: pipeline
- Added: 2026-11-17

### The in-run budget line prices total tokens at 6 per output token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: sprint-12-records spent 36,282 output against 2,147,268 total (59 per output), 4.3x over small's 500,000, while 6 per output predicted 217,692; the last ten backlog rows ran 3.5 to 59 per output; windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 were over 1,200,000 at 4.8 and 10.7; sprint-security's line said under at 131,132 output (lsp-container-b note 13, sprint-security note 8).
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its budget. Queued in `budget-prediction`.
- Category: pipeline
- Added: 2026-11-17

### Scout packs whose facts the contributor redoes
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: in sprint-security the scout took 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them at the same commit; backlog rows' scout share 18.4% to 40.1% (sprint-security note 7).
- Fix: start a scout only where its facts change a decision, or let the contributor take the pack as read; accepted when over the next five runs that start a scout its output stays under 10% of the run's with no drop in the quality first-pass rate. Queued in `scout-value`.
- Also: .claude/agents/scout.md
- Category: pipeline
- Added: 2026-11-17

### The benchmark phase measures records and docs-only runs that build nothing it measures
- Location: `.claude/workflows/deliver-change.js` (the benchmark phase's start condition)
- Why: sprint-12-records bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 tool calls, stopped at its cap; over the three sprint records runs bench took 15,099 of 127,367 output tokens (11.9%) and 23 of 222 calls, each finding allocations and rounds equal to main (bench first pass 3 of 3), so its result changed no decision (sprint-12-records retro note 4).
- Fix: record the bench phase as skipped, with its reason and 0 tool calls, on a run touching no file under `carat/`, `bin/`, `bench/`, or the Makefile; accepted when the next records or docs-only run shows it skipped and a change touching those paths is still measured.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-17

### A post-review prose edit in the package step refuses the push (lsp-container-b retro note 12)
- Location: the package step of `.claude/workflows/deliver-change.js`, the review-currency check of `tools/run_state.sh push`
- Why: a docs-only wording fix of `docs/architecture.md:275` invalidated the recorded check and security review, 1 refused push, the edit reverted and the stale Open3 sentence left on main; package 21 of 210 tool calls (10.0%).
- Fix: settle the advisories the package step may fix before the last review, or exempt pure prose edits from invalidating it; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit.
- Also: tools/run_state.sh, docs/architecture.md
- Category: pipeline
- Added: 2026-11-17

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: the last ten backlog rows ran 3.5 to 59 total per output; sprint-12-records 36,282 output projected 217,692 against 2,147,268 actual (over small 500,000 by 4.3x), windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 over 1,200,000 at 4.8 and 10.7, sprint-security's line said under at 131,132 output. Folds into `budget-prediction`.
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its size budget.
- Category: pipeline
- Added: 2026-11-17

### The scout's pack is redone by the contributor (sprint-security retro note 7)
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: sprint-security scout 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them; backlog rows scout share 18.4% to 40.1% over five runs. Folds into `scout-value`.
- Fix: accepted when, over the next five runs that start a scout, scout output stays under 10% of the run's output with no drop in the quality first-pass rate.
- Also: .claude/agents/scout.md
- Category: pipeline
- Added: 2026-11-17

### The benchmark phase measures records and docs-only runs (sprint-12-records retro note 4)
- Location: `.claude/workflows/deliver-change.js` benchmark phase; sprint-12-records run state note.4.
- Why: bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 calls on sprint-12-records, 15,099 of 127,367 (11.9%) and 23 of 222 calls over the three sprint-records runs, and found allocations and rounds equal to main 3 of 3, never changing a decision.
- Fix: skip the bench phase with its reason when the change touches no file under carat/, bin/, bench/, or the Makefile; accepted when a records run records bench skipped with 0 calls and a carat/ change is still measured.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-17

### The merge phase output on a green first-pass CI varies fivefold (check-parallel retro note 8)
- Location: .claude/workflows/deliver-change.js, the merge phase; queued in `merge-gate-integrity`
- Why: check-parallel's merge spent 22,685 of 239,451 output (9.5%) in 11 calls with 4 CI wait calls on a first-pass CI; of the last 20 lane rows 19 passed CI first, 6 of them above 10,000 merge output and the other 13 at 4,347 to 7,747.
- Fix: one CI wait and one merge per green run; accepted when over the next five runs whose CI passes first the merge phase stays under 8,000 output tokens.
- Category: pipeline
- Added: 2026-11-17

### The check-pass budget step changes no decision (check-parallel retro note 9)
- Location: .claude/workflows/deliver-change.js, the budget step at the check pass; queued in `budget-prediction`
- Why: check-parallel printed "no spent line returned" at its check pass; the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: remove the step or fold it into the close budget line; accepted when over the next five runs every budget step prints an under: or over: line, or the close line is the only one.
- Category: pipeline
- Added: 2026-11-17

### Scout and areas starts repeat what the planner and contributor establish (lsp-container-c retro)
- Location: `.claude/workflows/deliver-change.js` areas and scout phases
- Why: lsp-container-c's scout and areas cost 41,568 of 220,432 output (18.9%) and 24 of 119 calls (20.2%) for an implement of 27 calls, the planner having named the check site and the contributor re-verifying both scout findings; lsp-container 25.9%, lsp-container-b 15.3% of output. For `scout-value`.
- Fix: skip or shrink the scouts when the brief names its locations; accepted when over the next 5 runs scout and areas stay under 10% of output, implement calls at or under the last-10 feature median (38), first passes not lower.
- Category: pipeline
- Added: 2026-11-17

### The workflow treats a refused merged record as merged (sprint-14 sweep quality, merge-record-check retro 9)

- Location: .claude/workflows/deliver-change.js:1302 and the close's record chain.
- Why: the workflow sets state.merged and queues phase merge at the merger's sha even when run_state set merged refused it, so no merged record or history row is written and the lane stays open; one refused record in the close's && chain dropped 3 phase records and all 30 metric fields of merge-record-check (294,037 output, 181 calls).
- Fix outline: read back the merged record before treating the run as merged; a refused record reported without dropping the others. Queued in `merge-gate-integrity`.
- Category: pipeline
- Added: 2026-11-17

### The benchmark runs on a diff that touches no code (retro, third recording)
- Location: `.claude/workflows/deliver-change.js`, the bench phase start.
- Why: sprint-14-records spent 4,178 of 32,743 output tokens (12.8%) and 8 of 68 calls on bench for allocations all equal to main's and a us.insert 24% warning on a docs-only diff; over sprint-10 to sprint-14 records bench took 33,140 of 203,003 output tokens (16.3%) and 37 calls, first pass in all five; recorded before as sprint-12-records note 4 and sprint-13-records note 6.
- Fix: start no benchmark agent when the diff touches nothing under `carat/`, `bench/`, or `test/`, the row carrying main's recorded allocations and rounds; accepted when the next records row shows no bench phase and main's allocs and rounds.
- Category: pipeline
- Added: 2026-11-17

### Scouts run on a one-area removal the plan already maps (T1 efficiency)
- Location: `.claude/workflows/deliver-change.js`, the scout phase
- Why: ruby-structure-remove scout 33,374 output tokens and 17 calls, 24.6 percent of 135,491 output and 14.4 percent of 118 calls with areas=1, while the plan named every line range; scout share tab-close-c 13.2, markdown-reading-d 11.0, lsp-container-c 16.8, vim-line-commands-a 21.9, bar-colors 28.3 percent.
- Fix: skip or shrink the scout when the plan already names every file and range; accepted when the next one-area removal or revert runs with no scout start (or under 10,000 scout output tokens) and keeps first.check, first.quality, and first.security at 1.
- Category: pipeline
- Added: 2026-11-17

### The mid-run output-token overrun check flags runs their totals do not confirm
- Location: `.claude/workflows/deliver-change.js`, the overrun check at the check pass (output tokens times 6 against the size's total budget)
- Why: tab-close-c flagged 219,748 output tokens against 200,000 while its total, 830,180, stayed under 1,200,000; the last 10 feature rows have total-to-output ratios 2.2 to 7.9, not 6, and 6 of them passed 200,000 output tokens while only markdown-reading-c (1,902,958) passed the total budget.
- Fix: base the mid-run flag on recorded totals or a ratio taken from the lane history; accepted when, replayed over the last 10 feature rows, it flags only rows whose total_tokens exceeded their size budget.
- Category: pipeline
- Added: 2026-11-17

### The scout phase runs on a one-area removal whose plan names every location (ruby-structure-remove retro)
- Location: `.claude/workflows/deliver-change.js:184` (scoutTargets)
- Why: ruby-structure-remove's scout spent 33,374 output tokens and 17 calls, 24.6% of 135,491 output tokens and 14.4% of 118 calls, with 1 area, while the plan cited every file and line range and the contributor reversed the earlier diff exactly; scout share over recent feature rows 11.0% to 28.3%.
- Fix: the next one-area removal or revert runs without a scout start, or under 10,000 scout output tokens, keeping first.check, first.quality, and first.security at 1.
- Category: pipeline
- Added: 2026-11-17

### Quality re-reviews re-raise recorded advisories (vim-folds-a retro 25)

- Location: the quality phase of .claude/workflows/deliver-change.js.
- Why: in vim-folds-a the closed-window fold leak was raised 3 times (notes 5, 12, 17) and the fold-start duplication twice (15, 19); 13 advisories handed to packaging, 6 dropped; reviews 96,869 output tokens (20.1%) and 110 calls (31.6%).
- Fix outline: a later round knows the recorded advisories and raises none again by location and cause; accepted when one run records no advisory twice.
- Category: pipeline
- Added: 2026-11-17

### A carried review rests only on the moved line the checker copies back
- Location: .claude/workflows/deliver-change.js:935 (carryReviews)
- Why: Security Low (confidence 5). It records quality and security as passed at the merged head from the line the checker agent returns as `moved`, never running `moved` itself, and neither the run state nor the merge gate keeps an independent record, so a misreported or invented 'the change is the same' line gets a security pass recorded at a head no review saw, which the merge gate accepts.
- Fix: Have `tools/run_state.sh moved` write its verdict to the run state (for example `moved.<head> <from> same`) and have `run_state.sh review ... carried` or the merge gate refuse a carried review unless that record names the same head and from commit, or have the queued record command re-run `moved` before writing the carried pass.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-18

### Reviews rerun after a main-moved merge read every commit of the moved main
- Location: .claude/workflows/deliver-change.js:855 (narrowedFrom)
- Why: Correctness. When the reviews run again after a main-moved merge, narrowedFrom returns the pre-merge pass, so the quality and security reviews read `git diff <pass> HEAD`, which holds every commit main gained, and can block the change on main's code or spend the review on code that is not the change's.
- Fix: Skip the narrowing and review the whole branch diff (origin/main...HEAD) when the check that preceded the reviews ran with movedFrom set; add a tools_test or workflow case that asserts the review range after a main-moved merge.
- Category: pipeline
- Added: 2026-11-18

### A check start returns a pass at a commit other than the lane head (sprint-size-six retro)
- Location: the check phase of `.claude/workflows/deliver-change.js` and `check` in `tools/run_state.sh`
- Why: sprint-size-six's first check verdict passed at the base 25604e0ec359, not the head 2d4d9a8ffa16, so the check reran (1 of 2) with no fix round: check 40,322 output tokens in 8 calls, 22.2 percent of 181,434 and more than implement's 38,917; 4 of the last 20 backlog rows spent over 35,000 on the check.
- Fix: a check start reaches its verdict at the head on the first start; accepted when a check can no longer return a pass at another commit and the next 5 runs with no fix round each spend under 12,000 check output tokens.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-18

### The package step reverts advisory fixes and drops their findings (evidence for package-advisory-edit)
- Location: the package step of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 5.
- Why: package 10,126/23 against the feature median of 15 calls; quality 4 advisories, 1 appended; third run after motions-search-tidy 16,259/22 and record-squash-commit 38,843/17.
- Fix: fold into backlog pool item `package-advisory-edit`; accepted when over 3 runs with advisories each one not fixed at the reviewed commit is in docs/findings and no revert commit is on the branch.
- Category: pipeline
- Added: 2026-11-18

### The check-pass budget line converts output at a fixed 6 per token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 6.
- Why: it noted 197,007 output as 98.5 percent of medium while the run closed at 893,872 total of 1,200,000; the last 10 feature rows' total to output ratio runs 2.42 to 7.94, so the line notes overruns the totals never show and changes no decision.
- Fix: drop the line, or make its over agree with the final total-token budget line on the last 10 medium feature rows.
- Category: pipeline
- Added: 2026-11-18

### A current area pack is scouted again for a missing location (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` scout reuse
- Why: the build-and-ci pack, current at 8b54500, was discarded because its Locations line lacked `tools/scan_text.sh`; the scout then spent 42,854/20, 33.6 percent of output tokens and 1.34 times implement's 31,927, against 8.7 to 19.4 percent in the last medium backlog rows.
- Fix: reuse a pack current at the run's commit and add only the named locations; accepted when such a delivery spends under 15 percent of output tokens on the scout phase.
- Also: tools/scan_text.sh
- Category: pipeline
- Added: 2026-11-18

### The medium merge call cap overruns on CI waiting alone (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` CALL_CAPS
- Why: a green first-pass CI with rework 0 made 16 merge calls over the medium cap of 14 with ci_wait_calls 6 and CI 8.4 min (record-squash-commit 14, markdown-reading-d 13 at the same wait count), and the overrun note then asks the planner to re-estimate a change whose size did not cause it.
- Fix: size the merge cap by CI waits, not by the estimate; accepted when the next three medium runs with first-pass green CI of 7 to 12 minutes record merge calls at or under the cap and no merge overrun note.
- Category: pipeline
- Added: 2026-11-18

### The planner starts on a placed item (merge-main-path retro 5)

- Location: .claude/workflows/deliver-change.js, plan-needed in tools/run_state.sh.
- Why: merge-main-path's brief and the user's answers fixed its tier, placement, sprint count, and size, yet its plan start spent 63,196 output tokens, 28.1 percent of the run's output; evidence for "### The planner runs on a placed first item (evidence for plan-skip-placed)".
- Fix outline: skip or bound the planner when the brief fixes every decision; accepted when the next such run's plan phase is at or under about 19,000 output tokens or absent with the same decisions.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-18

### Two blank lines left where figuresFirst was removed
- Location: .claude/workflows/deliver-change.js:1007
- Why: removing figuresFirst left two blank lines between mayFix and qualityTask (also reported at :1009, merged here).
- Fix: keep one blank line.
- Category: pipeline
- Added: 2026-11-18

### Fixed-in-place state lives only in memory across a resume
- Location: .claude/workflows/deliver-change.js:1169
- Why: fixedInPlace, awaiting, and offered live only in memory while seed rebuilds every quality-advisory note on a resume before the push, so a finding confirmed fixed in place in an earlier start (or offered just before a stop) is handed to docs/findings again.
- Fix: note each confirmed fix as fixed-in-place in the run state and have seed fill fixedInPlace from those notes.
- Category: pipeline
- Added: 2026-11-18

### Run-check prompt may run moved after a failed check
- Location: .claude/workflows/deliver-change.js:924
- Why: checkRunTask lists the moved line as step 3, "Then", after the pass-only step 2, while the old prompt said once the check passed, so a run start may run moved (which writes the moved key) after a failed check.
- Fix: begin step 3 with "Only after that pass" as step 2 does.
- Category: pipeline
- Added: 2026-11-18

### In-place-only rounds inflate the rework metric
- Location: .claude/workflows/deliver-change.js:1268
- Why: an in-place-only round goes through contributor('fix'), which increments rework, so metric.rework, the first-pass picture the planner reads, and the 'still blocked after N fix rounds' stop mix advisory clean-ups with blocking fixes.
- Fix: count in-place rounds in their own metric while still bounding them by ROUNDS.
- Category: pipeline
- Added: 2026-11-18

### scoutTargets matches a location as a substring of the brief (pipeline-diet quality)
- Location: .claude/workflows/deliver-change.js:195 (scoutTargets)
- Why: loose match: scoutTargets names an area when String(brief).includes(pathOf(l)), so a directory or prefix location (tools/, carat/domain) counts as named whenever the brief names any file under it, skipping its scout.
- Fix: match the location's path as a whole token of the brief (delimited by backticks, spaces, or punctuation).
- Category: pipeline
- Added: 2026-11-18

### A scout runs for an area the change barely edits (plugin-lazy-activate retro 12)
- Location: `.claude/workflows/deliver-change.js`, the scout plan from the areas start.
- Why: plugin-lazy-activate spent 57,113 output tokens and 40 calls on scouts (16.6 percent of 343,926 output, 16.5 percent of 242 calls) for 3 packs, one (build-and-ci) for 8 of 813 changed lines; scout shares tab-close-b 25 percent, tab-close 21 percent, secret-patterns 33.6 percent.
- Fix: skip or fold the scout of an area whose planned edit is a few lines; accepted when the scout share of output over the next 10 feature runs has a median at or under 12 percent with first.check and first.quality rates not lower.
- Category: pipeline
- Added: 2026-11-18

### Packaging writes advisory findings into the findings file by hand (tab-close-d retro)
- Location: `.claude/workflows/deliver-change.js` package phase, `docs/findings/<change>.md`.
- Why: packaging turned the run state's quality advisories into findings entries and a rewritten pull request text by hand in two docs-only commits, and the next quality review flagged the entries' format; package 60,830 output tokens/51 calls against a last-ten feature median of about 8,000/15.
- Fix: a `tools/run_state.sh` command appends the advisory notes to `docs/findings/<change>.md` in the file's one format; accepted when the next five medium runs' package phase stays near the median.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-18

### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-18

### The benchmark phase starts an agent for a diff with no file under carat/ (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` benchmark phase.
- Why: with 0 carat files changed it builds base and change and reports every key unchanged: bench 3,547/6 in sprint-16-records, 4,178/8 in sprint-14-records, 3,467/7 in sprint-15-records, 11,192 output and 21 calls over 3 runs, 0 differences.
- Fix: record the bench phase without an agent start when no measured file changed; accepted when the next records row shows no bench share.
- Category: pipeline
- Added: 2026-11-18

### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-18

### The advisory commit-prefix strip is written twice in the delivery workflow (sprint-17 review quality)

- Where: `.claude/workflows/deliver-change.js:1119` and `:791` (`addAdvisories`), and two blank lines in a row at `:1009`, at 522a0e1.
- Why it matters: fixed-in-place matching depends on the two copies of the regular expression staying identical; the blank lines are left from a removal.
- Fix outline: one helper used by both, one blank line. Fold into the next pipeline change editing the file.
- Category: pipeline
- Added: 2026-11-18

### The merge phase spends output out of proportion to its calls (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the merge phase, and `.claude/agents/merger.md`
- Why: guide-colors merge took 26,423 output tokens for 11 calls and 4 CI-wait calls (9.1 percent of 290,842) on a 7-minute green CI; the last 10 feature rows range 4,992 to 98,694 merge output at 10 to 21 calls.
- Fix: a run green on its first CI pass keeps its merge phase under 10,000 output tokens; accepted over 5 consecutive runs.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-18

### A passing check phase costs a full agent start (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the check phase, and `.claude/agents/checker.md`
- Why: guide-colors check took 30,277 output tokens for 5 calls over two passes with all 9 stages passing (10.4 percent of 290,842), though the stages are deterministic; the benchmark already records equal figures without an agent.
- Fix: record a check phase whose stages all pass without an agent's reasoning, or with a minimal start; accepted when such a phase records under 3,000 output tokens.
- Also: .claude/agents/checker.md
- Category: pipeline
- Added: 2026-11-18

### The merge phase spends output out of proportion to its calls (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the merge phase, and `.claude/agents/merger.md`
- Why: guide-colors merge took 26,423 output tokens for 11 calls and 4 CI-wait calls (9.1 percent of 290,842) on a 7-minute green CI; the last 10 feature rows range 4,992 to 98,694 merge output at 10 to 21 calls.
- Fix: a run green on its first CI pass keeps its merge phase under 10,000 output tokens; accepted over 5 consecutive runs.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-18

### A passing check phase costs a full agent start (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the check phase, and `.claude/agents/checker.md`
- Why: guide-colors check took 30,277 output tokens for 5 calls over two passes with all 9 stages passing (10.4 percent of 290,842), though the stages are deterministic; the benchmark already records equal figures without an agent.
- Fix: record a check phase whose stages all pass without an agent's reasoning, or with a minimal start; accepted when such a phase records under 3,000 output tokens.
- Also: .claude/agents/checker.md
- Category: pipeline
- Added: 2026-11-18

### The calibration comment names the tier twice

- Location: `.claude/workflows/deliver-change.js:129`
- Why: the comment says the tier twice ("the tier the model: line of the agent's file names ... whichever tier that is"), wordier than the rule it states.
- Fix: "The tier is agent, the agent file's model: line (the only place a tier is named; tools/tools_test.sh compares them), or session, the session's model".
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-19

### Records changes spend fix rounds on advisories only groom may fix (sprint-18-records retro 12)
- Location: `.claude/workflows/deliver-change.js` review rounds on a records change
- Why: 4 of 7 first-round advisories (backlog duplicates, stale security entries, fold format, map repeat) need backlog entries merged or removed, which CLAUDE.md leaves to groom, and 3 of the 4 second-round advisories repeat them with shifted lines; rework 2 with 0 blocking, reviews=25498/34 (29.5% of 86,421 output, 26% of 129 calls).
- Fix: an advisory in groom's own output on a records change goes to the findings file with no fix round; accepted when the next 3 records runs show rework 0 when blocking is 0. Near `review-lite`.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-19

### The benchmark agent runs on records changes that touch no code (sprint-18-records retro 13)
- Location: `.claude/workflows/deliver-change.js` bench phase
- Why: on sprint-18-records it rebuilt dev-build, test-build, and bench-budget in the lane and a base worktree to find allocations and rounds equal: bench=4721/14 (10.9% of 129 calls); sprint-16-records bench=3547/6, sprint-17-records bench=4147/6.
- Fix: a change with no file under `carat/`, `bench/`, or the Makefile records the bench phase as skipped with no agent; accepted when records runs show bench 0/0. Joins `bench-skip-no-code`.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-19

### Advisory-only fix-in-place rounds count as rework (contributor-tier-trial retro 8)
- Location: `.claude/workflows/deliver-change.js` (rework counting of fix-in-place rounds); joins the queued `advisory-findings-auto` (backlog Pool 27).
- Why: contributor-tier-trial spent rework 2 of 3 with 0 blocking findings (7 advisories over 3 quality passes at 0979253d226d, a47624b033bf, 96085591e512); 8 of the last 20 rows with every first pass 1 spent 12 rework rounds, and rework-2 rows took 61.0 to 118.0 min against 44.8 for vim-folds-b at 0; reviews=36277/65, 31% of 207 calls.
- Fix: accepted when, over the next 10 metrics rows, rows whose first passes are all 1 average at most 0.5 rework rounds without a lower quality first-pass rate.
- Category: pipeline
- Added: 2026-11-19

### A resumed implement start that commits nothing costs a full implementation (contributor-tier-trial retro 9)
- Location: `.claude/workflows/deliver-change.js` (the resume's implement start).
- Why: at head 96085591e512 every stage was 0 and every task done, yet implement took 78,908 of 165,645 output tokens (48%) and 73 of 207 calls (35%) to change nothing; check-stage-order's whole implement was 12941/27.
- Fix: accepted when a resume whose head already passes every stage and has every task checked records implement at most 15,000 output tokens and 25 calls.
- Category: pipeline
- Added: 2026-11-19

### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))

- Location: `.claude/workflows/deliver-change.js:952` (review-lite's settled round), `tools/gates.sh` settled_at, `tools/run_state.sh` settled_round.
- Why: in an advisory-only round that changes only records the security review does not run again, and the records include `docs/backlog.md` and `docs/findings/*.md`, so a contributor deleting or rewording a security entry there reaches the merge with no security reviewer seeing it; only the sprint-end combined-diff review would catch it.
- Fix: refuse to settle when the diff since the settled commit removes or changes an existing line of `docs/backlog.md` or `docs/findings/*.md` (append only), else run the security review again; a tools-test case each way. Queued in `review-lite-docs`.
- Also: tools/gates.sh, tools/run_state.sh
- Category: security
- Added: 2026-11-19

### closeAdvisories trusts the contributor's reported head to skip the re-review
- Location: .claude/workflows/deliver-change.js, closeAdvisories (head === before)
- Why: a closing start that committed code but reported the old head would skip verify() in the workflow; the pre-push and merge gates (settled_at) still refuse a security pass that code changed since, so nothing is bypassed in practice. The workflow holds no shell, so a lane head read needs a new record start (new behavior).
- Fix: have the checker's verdict commit or a rev-parse record start give the lane head, compare it with before, and skip verify() only when they match.
- Category: pipeline
- Added: 2026-11-19

### closeAdvisories trusts the contributor's self-reported head
- Location: .claude/workflows/deliver-change.js, closeAdvisories (around line 1383 and 1404)
- Why: when the closing start reports the earlier head, verify() and the security re-review are skipped, and since c5285fbabaac the same comparison clears awaiting; a start that committed code but reported the old head (for example after injection carried in advisory text) would reach package without a fresh workflow security review. The pre-push and merge gates (tools/gates.sh settled_at) still refuse a stale security pass, so nothing is bypassed in practice.
- Fix: compare the lane's actual HEAD (git rev-parse HEAD, read by a record start or taken from the checker's verdict commit) with before, not the returned head, before skipping verify() and clearing awaiting. Defense in depth only.
- Also: tools/gates.sh
- Category: pipeline
- Added: 2026-11-19

### closing figures are a lower bound after a resume during the closing re-review
- Location: .claude/workflows/deliver-change.js:1400 and openspec tasks 5.6 of closing-loop
- Why: the comment says final figures follow the early flush, but a resume during the closing re-review restores closed 0 left N, closeAdvisories returns at once, and awaiting and fixedInPlace are not restored, so advisories_closed stays 0 however many the re-review confirms.
- Fix: word the comment and the task as a lower bound on a resume, or record the confirmed count from the resumed re-review's fixed_in_place.
- Category: pipeline
- Added: 2026-11-19

### Escalation triggers have no driven test
- Location: .claude/workflows/deliver-change.js:934, :935, :1326
- Why: only escalate itself is driven in tools/tools_test.sh; the three call sites (no result, self-check mismatch, second blocking quality round) are not exercised, so a removed trigger passes.
- Fix: drive contributor() with a stubbed null result and a self_check mismatch result, and reviews() with two blocking quality results, asserting escalated.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-19

### Critical read in the queue line matches the word anywhere
- Location: .claude/workflows/deliver-change.js:1654
- Why: /critical/ matches the word in the queue line's name or reason, so a non-critical item whose reason says critical notes a spurious "plan: critical value not read", and unlike the planned-path note the note omits the unread text.
- Fix: test for critical inside the parenthesis only (for example /[(,] ?critical\b[^)]*\)/) and append the unread text as the planned-path note does.
- Category: pipeline
- Added: 2026-11-19

### Skipped-plan critical note has no driven test
- Location: .claude/workflows/deliver-change.js:1654
- Why: the skipped-plan note is top-level code no test drives, nor is the planned-path note at :1674.
- Fix: move the skipped-plan critical read into a helper returning the rule or the note and drive it in tools/tools_test.sh calib_js with a read, an unread, and a no-critical queue line.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-19

### The pull request text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js (prTextReview call after the package step)
- Why: it runs only in the start that packages, so a resume after the push never reviews the text; no verdict of it is recorded
- Fix: record the review's verdict (a phase or a note the run state returns) and run it on resume when none is recorded
- Category: pipeline
- Added: 2026-11-19

### Text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js:1606 and :1616
- Why: the pull request text review runs only in the start that packages; a resume past the package phase skips it silently (still present, recorded instead of fixed)
- Fix: record the text review's verdict and run it on resume when none is recorded
- Category: pipeline
- Added: 2026-11-19

### Advisory fixes take two paths and an advisory-only round counts as rework (closing-loop retro 10)
- Location: `.claude/workflows/deliver-change.js` (the in-place round, `inPlaceRound` 'alone', and the closing loop at package)
- Why: closing-loop rework 2 of 3, round 2 advisory-only (note 8, 0 blocking), its rerun (tools-test 135 s, every review again) raised note 9; reviews 43,866 of 191,898 output tokens (22.9%), 57 of 233 calls; quality first pass 101 of 183.
- Fix: keep one advisory path, so an advisory-only round is never a rework round and a run starts at most one contributor for advisories; accepted when a tools-test case shows a run with advisory-only reviews records rework unchanged and starts exactly one advisory start.
- Category: pipeline
- Added: 2026-11-19

### Advisory fixes take two paths and an advisory-only round counts as rework (closing-loop retro 10)
- Location: `.claude/workflows/deliver-change.js` (the in-place round, `inPlaceRound` 'alone', and the closing loop at package)
- Why: closing-loop rework 2 of 3, round 2 advisory-only (note 8, 0 blocking), its rerun (tools-test 135 s, every review again) raised note 9; reviews 43,866 of 191,898 output tokens (22.9%), 57 of 233 calls; quality first pass 101 of 183.
- Fix: keep one advisory path, so an advisory-only round is never a rework round and a run starts at most one contributor for advisories; accepted when a tools-test case shows a run with advisory-only reviews records rework unchanged and starts exactly one advisory start.
- Category: pipeline
- Added: 2026-11-19

### First-pass miss marker matches anywhere in the text
- Location: .claude/workflows/deliver-change.js:430
- Why: the marker regex matches anywhere in the text, case-sensitively, so a negation such as not a first-pass miss counts and First-pass miss does not.
- Fix: match the marker only right after the location findingAt returns, as the agent file asks, case-insensitively.
- Category: pipeline
- Added: 2026-11-19

### Whole-branch quality input lists no blocking findings
- Location: .claude/workflows/deliver-change.js:906
- Why: the agent file excludes the blocking findings its input lists, but priorQuality lists them only on the scoped path; on the whole-branch path none are listed, so the reviewer marks a still-unfixed blocking finding first-pass miss and only qualitySplit's prior filter keeps the record right.
- Fix: list the last review's blocking findings in the whole-branch input too when qualityBlocking holds them.
- Category: pipeline
- Added: 2026-11-19

### The known argument of the quality handler is derived inline and untested
- Location: .claude/workflows/deliver-change.js:1207
- Why: the commit of review.quality equal to qualityAt is derived inline in the handler and never run by a test, so the resumed-without-notes case is unproven.
- Fix: compute it in a small pure helper over ran and qualityAt and test it through speed_js.
- Category: pipeline
- Added: 2026-11-19

### One-use alias of split.raised
- Location: .claude/workflows/deliver-change.js:1209
- Why: const raised = split.raised is a one-use alias.
- Fix: concat split.raised directly.
- Category: pipeline
- Added: 2026-11-19

### An advisory-only fix round re-runs every review (sprint-19-records retro 5)
- Location: `.claude/workflows/deliver-change.js` (the fix-in-place round's re-review); joins the queued `rework-review-repeat` (backlog Pool 21).
- Why: sprint-19-records spent rework 1 on 4 advisory findings and 0 blocking, 1 fixed in place and 3 recorded; the second round re-ran check (passed), security (0 findings), and quality (0 blocking, 3 advisory); reviews took 13,756 of 34,522 output tokens (40%) and 27 of 69 tool calls (39%), as on sprint-17-records (30,387 of 72,515, 42%) and sprint-18-records (25,498 of 86,421, 30%), both rework 2.
- Fix: a round that fixes only advisory text in the change's own OpenSpec files does not re-run security and quality on the unchanged rest of the diff. Accepted when such a run records no second security and quality start and records-change rework drops to 0.
- Category: pipeline
- Added: 2026-11-19

### The benchmark starts on a docs-only change for want of a recorded measurement (sprint-19-records retro 6)
- Location: `.claude/workflows/deliver-change.js` (the benchmark phase's start condition); joins the queued `bench-skip-no-code` (backlog Pool 26).
- Why: sprint-19-records' benchmark spent 3,513 output tokens and 5 calls (10% of output) on a docs-only diff, building base and change only to report no difference, started because build/metrics was missing; sprint-17-records 4,147 / 6, sprint-18-records 4,721 / 14; bench passes first 177 of 178.
- Fix: a change touching no file under carat/, bin/, test/, or bench/ starts no benchmark agent and carries its bench result as equal. Accepted when a docs-only or records-only run records no benchmark start.

- quality advisory, docs/backlog.md:8596, stale entry: the folded 'guide-colors retro entries are folded twice' note cites old line numbers and is half resolved, since this groom removed the advisory-only copies while 'The merge phase spends output out of proportion to its calls' (:8372, :8386) and 'A passing check phase costs a full agent start' (:8377, :8391) stay duplicated. Fix: list :8386 and :8391 as duplicate and this note as fixed in the next groom.txt.
- quality advisory, docs/backlog.md:8383 and :8402, the two SECURITY_MARK security entries stay open although docs/queue-feature.md's Sprint 20 notes say b5b0aec (#214) fixed them and the folded entry at :8604 asks to close them. Fix: list both as fixed by b5b0aec in the next groom.txt after checking its tools-test cases.
- quality advisory, docs/backlog.md:8555, :8574, :8619, format: folded headings follow the previous entry's Fix line with no blank line, the fold defect the entry at :8608 already records. Fix: have groom put a blank line before each folded heading (groom-fold-format) and fold this into that entry.
- Also: docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-19

### FixedInPlace (sprint-20 sweep quality, deliver-change.js:1374)

- Location: `.claude/workflows/deliver-change.js:1374`
- Why: fixedInPlace (and awaiting) are never restored by seed, so a run resumed after an advisory was confirmed fixed in place, or stopped during the closing loop's re-review, hands every such advisory to the package step as open (handOver, line 876) and keeps closingFigures at 0 closed, N left (closeAdvisories returns at line 1426)
- Fix: record each confirmed fix as a run-state note in confirmInPlace and rebuild fixedInPlace from those notes in seed, then recompute closingFigures after the resumed verify, with a tools_test.sh js case for the resume
- Category: pipeline
- Added: 2026-11-19

### An advisory-only round and the closing loop are two contributor starts for one kind of finding
- Location: .claude/workflows/deliver-change.js (finder-match-strict retro note 14); merge into `advisory-findings-auto` (backlog queue Pool 20)
- Why: after finder-match-strict's blocking fix, the fix-in-place round (3 docs advisories) and the closing loop (1 advisory closed, 1 left) each re-ran the check and the reviews (heads 752056e and 0409630) for 4 one-line doc edits; closing phases also in finder-grep (6,555/19), contributor-tier-routing (3,210/9), finder-grep-c (2,185/3), merged-record (1,194/2).
- Fix: advisories left after the last blocking fix get at most one contributor start and one re-check; accepted when a run with no blocking finding after round 1 shows at most one advisory start in its phases.
- Category: pipeline
- Added: 2026-11-20

### An advisory-only round counts as rework and reruns every review (vim-folds-c retro 3, near-same to the pool's rework-review-repeat)
- Location: .claude/workflows/deliver-change.js, the round settling after a quality-advisory fix; docs/queue-backlog.md Pool `rework-review-repeat`
- Why: vim-folds-c recorded rework 1 with every first pass 1; the round fixing 2 quality advisories reran the check and both reviews, 30,104 plus 41,657 = 71,761 output (24.5% of 292,577), the second security pass finding 0; 6 of the last 20 lane rows record rework 1 or 2 with every gate first.
- Fix: fold into `rework-review-repeat`; accepted when, over the next 3 runs whose only round fixes advisories without a behavior change, metric.rework stays 0 and that round's check plus reviews output is under half of the first pass's.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-20

### Findings append is not idempotent across starts

- Location: `.claude/workflows/deliver-change.js` (the findings append a resume repeats), seen in the finder-grep-preview findings, line 35
- Why: finder-grep-preview retro note 13: the file carries the retro notes twice (lines 35 to 48 repeat lines 1 to 11) and the security Low twice (lines 26 and 31), 14 of its 48 lines repeats, which cost the last quality round 2 advisories, both left (advisories_closed 0 of 2).
- Fix: accepted when a tools-test case hands the same findings to the append twice, as a resume does, and each entry lands once.
- Category: security
- Added: 2026-11-20

### An overrun note is written at every check pass

- Location: `.claude/workflows/deliver-change.js` (the overrun note per check pass); near-same as the backlog queue's `check-pass-budget-flag`, merge into it
- Why: finder-grep-preview retro note 14: 4 overrun notes in one run (notes 7, 8, 9, 12: 213,428, 336,889, 361,702, 409,157 output against medium's 200,000), each superseding the last, none changing a decision; finder-match-strict 3 of 4.
- Fix: accepted when a run records at most one output overrun note and the planner's overrun input is unchanged.
- Category: pipeline
- Added: 2026-11-20

### Reviews spend a third of a run's tool calls for an eighth of its output

- Location: `.claude/workflows/deliver-change.js` (the review rounds)
- Why: finder-grep-preview retro note 15: 73 of 237 calls (30.8%) for 54,543 of 446,611 output (12.2%), the last round finding 0 blocking, 1 Low, 2 advisories; finder-grep 80 of 268 (29.9%), contributor-tier-routing 73 of 231 (31.6%), sprint-count-t0 59 of 225 (26.2%).
- Fix: accepted when the reviews' share of tool calls over the next five lane rows falls below 20%, the security review still run on every pushed head.
- Category: security
- Added: 2026-11-20

### The benchmark agent starts when it can decide nothing (vim-case-operators retro 20, pr-trust-lows retro 7)
- Location: `.claude/workflows/deliver-change.js`, the bench phase's start condition; `tools/metrics.sh`.
- Why: vim-case-operators started it twice (8f0ce99, cbd9783) for a key absent from main's recorded row though main's measurement gave the same figure (allocs.grep 842.6 on both sides): 101,841 of 568,067 output tokens (17.9 percent), 15 of 276 calls. pr-trust-lows started it 4 times on a diff touching no carat/, bench/, or test/ file: 16,538 output tokens, 24 of 237 calls (10.1 percent), every key equal, 0 findings. History bench first pass 205/206. Near the entry "The benchmark agent reruns after a head move that changes no carat file (grep-long-files retro 6)" and the backlog queue's `bench-skip-no-code`.
- Fix: start no agent when the diff touches no carat/, bench/, or test/ file, or when a key main's row lacks equals main's own measurement; accepted when such runs record review.bench skipped with no bench start, the record still passing, and a tools-test case covers each condition.
- Merged: ### The benchmark starts on a diff touching no carat, bench, or test file (pr-trust-lows retro 7)
- Location: `.claude/workflows/deliver-change.js`, the bench phase's start condition; `.claude/agents/benchmark.md`.
- Why: pr-trust-lows made 4 bench starts, 24 of 237 calls (10.1 percent) and 16,538 output tokens, each building origin/main in a temporary worktree, every allocation and round key equal, the release bench skipped each time, 0 findings; bench first pass 204/205. Near the backlog queue's `bench-skip-no-code` (Pool 22).
- Fix: skip the bench start when the diff touches no carat/, bench/, or test/ file; accepted when such a run records no bench start, review.bench says skipped, and the record still passes.
- Also: tools/metrics.sh, .claude/agents/benchmark.md
- Category: pipeline
- Added: 2026-11-20

### Advisory-only fix rounds rerun the check and both reviews at full cost (vim-case-operators retro 21)
- Location: `.claude/workflows/deliver-change.js`, the rework count and the review reruns.
- Why: vim-case-operators rounds 1 and 2 fixed 3 and 1 advisories, round 2's fix caused the one blocking finding (visual r), and security ran 5 times with 0 findings; rework 3 of 3 with every gate first; reviews 121,744 of 568,067 output tokens (21.4 percent), 74 of 276 calls (26.8 percent); rework 204 over 206 changes. Near the entry "A fix-in-place round is offered for an advisory the contributor may not fix (grep-long-files retro 7, use-case-surface-b retro 5)" and `rework-review-repeat`.
- Fix: an advisory-only round does not count toward the 3-round limit and security reruns only on the final head or a diff touching new files; accepted when a run whose first quality pass has 0 blocking findings runs the security review at most twice.
- Category: pipeline
- Added: 2026-11-20

### A records run's advisories located in docs/backlog.md open fix rounds the contributor cannot act on
- Location: the advisory fix rounds of `.claude/workflows/deliver-change.js` on a `sprint-N-records` change; near the backlog queue's Pool item `rework-review-repeat` (an advisory-only round counts as rework).
- Why: sprint-21-records rework 2 of 3 from two advisory-only rounds plus one close-advisories start, 2 of those 3 starts made no commit, advisories_closed 0 left 4, all four in docs/backlog.md, which a delivery never reads; sprint-17 to -20-records rework 2, 2, 1, 1 against 0 for sprint-15 and -16 (sprint-21-records retro note 8).
- Fix: record such an advisory once in docs/findings/ and open no fix round for it; accepted when such a records run reaches packaging with rework 0 and no contributor start that ends with no commit.
- Category: pipeline
- Added: 2026-11-20

### A repeated advisory of a records-only fix round is recorded twice
- Location: the package step's advisory recording in `.claude/workflows/deliver-change.js`, the advisories_left count of the run state.
- Why: sprint-21-records notes 5 and 6 at 934b93604302 repeat notes 3 and 4 at 528d21f2c165, so advisories_left is 4 for 2 distinct findings and docs/findings/ counts one defect twice; the quality review 2557/5 and the closing start 991/1 were spent on the repeats (sprint-21-records retro note 9).
- Fix: match a later round's advisory to an earlier one by location and finding before recording; accepted when a records-only fix round's repeats are not re-recorded and advisories_left equals the distinct findings.
- Category: pipeline
- Added: 2026-11-20

### The benchmark agent reruns after a head move that changes no carat file (grep-long-files retro 6)
- Location: `.claude/workflows/deliver-change.js`, the bench phase's start condition; `tools/metrics.sh`.
- Why: grep-long-files spent 158,719 of 586,295 output tokens (27 percent) and 32 of 285 tool calls on 3 benchmark starts at 5dd6b49f95e5, 56fb6d90553c, d4ee3a660680, each with no regression and only the new key allocs.grep 842.6; the third followed a merge of main touching only README.md, docs/codebase-map.md, tools/tools_test.sh. Near the backlog queue's `bench-skip-no-code`.
- Fix: start the benchmark at most once when every shared allocation and round key equals main's and the check only adds keys, and never after a fix or merge changing no carat/, test/, or bench/ file; accepted when such a run's bench share of output tokens is under 10 percent.
- Also: tools/metrics.sh, README.md, docs/codebase-map.md, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-20

### A fix-in-place round is offered for an advisory the contributor may not fix (grep-long-files retro 7, use-case-surface-b retro 5)
- Location: `.claude/workflows/deliver-change.js`, the advisory fix-in-place round and the rework count; the advisory at the removed findings file of grep-long-files, line 10 and `tools/run_state.sh:1926`.
- Why: grep-long-files recorded rework 2 of 3 with every first pass 1; its second round's one advisory pointed at a file outside the branch diff and a mid-file edit of an append-only findings file, so the round made no commit. use-case-surface-b recorded rework 1 with check, security, quality, bench, and CI all first and 0 blocking quality findings (2 advisory), yet its second pass at 026dd754eb37 reran dev-build 67 s, test-build 180 s, diagnose 211 s, tools-test 208 s and both reviews (22696/28). Status shows 199 rework rounds over 203 changes. Near the backlog queue's `rework-review-repeat` (Pool 17).
- Fix: record an advisory the contributor may not fix in place for the findings file without a contributor start, and count an advisory-only round as no rework, skipping the second check and security review; accepted when a run whose first quality pass has 0 blocking findings records rework 0 and runs the check once.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-20

### The merge phase of a green-first-CI run costs the most of the close phases (use-case-surface-b retro 3)
- Location: `.claude/workflows/deliver-change.js`, the merge phase; `.claude/agents/merger.md`.
- Why: use-case-surface-b's merge took 80,031 output tokens on 12 calls (6,669 a call), 29.8 percent of its 268,714 output tokens, with CI green first in 9 min and 6 wait calls; the highest of the last 20 lane rows, whose merge phases ran 4,219 to 47,542 (backlog median about 15,000, feature 6,047 to 32,655).
- Fix: find what a green-first merge spends beyond the wait and the squash message and cut it; accepted when the merge phase stays at or under 20,000 output tokens in each of the next 5 runs whose CI is green on its first pass.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-20

### A records-only change still runs the benchmark and rebuilds the lane (sprint-22-records retro note 3)
- Location: the bench phase of `.claude/workflows/deliver-change.js` and the check's scoped metrics stage, `tools/run_state.sh`; seen in the sprint-22-records run state.
- Why: a diff touching no file under carat/, bin/, test/, or bench/ ran the benchmark, which rebuilt the lane because the check scoped its metrics stage to 0s, hit its 10-call cap, and found all 22 keys equal: bench=5455/10 was 11.6 percent of 47025 output tokens and 11 percent of 90 calls; records rows bench 3547/6, 4147/6, 4721/14, 3513/5, 4548/5 over sprints 16 to 20, none with a regression; sprint-21-records ran none. T1 pipeline efficiency, for the backlog lane.
- Fix: accepted when the next records run shows no bench phase and no lane build, while a code change still fails metrics-compare on a regression.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-20

### Advisory-only rounds chain on their own fixes (status-winbar-tabs-b retro note 16)
- Location: `.claude/workflows/deliver-change.js` (the rework loop), joining the queued backlog Pool 9 `closing-loop-fold`; `test/editor_tab_flows.rb` (the helper the advisories hit).
- Why: every quality pass of status-winbar-tabs-b was blocking=0 (4 passes, 4+1+3+1 advisories) and every security pass found 0, yet two fix rounds and a closing start ran 3 more check and review chains; 6 of 9 advisories (notes 4 to 8, 14) were on the helper the previous advisory fix wrote; output 231,243 at the first check pass and 419,768 at the last, so 188,525 of 544,079 (34.7 percent) went to advisory-only rounds; rework 2 or more in 11 of the last 20 lane rows.
- Fix: a run whose quality passes are all blocking=0 runs at most one fix-and-review chain after its first pass, and an advisory on code an advisory fix added is recorded, not fixed again; accepted when the next such run shows one chain.
- Also: test/editor_tab_flows.rb
- Category: pipeline
- Added: 2026-11-21

### The check reports main's commit, not the head (status-winbar-tabs-b retro note 17)
- Location: the checker start in `.claude/workflows/deliver-change.js`, evidence for the queued backlog Pool 11 `check-at-head`.
- Why: 2 of 6 check starts of status-winbar-tabs-b reported a pass at main's 3af2fc9099f3 instead of heads b5df62c55abd and 535eafb3312b, each needing a rerun; check 100,640 of 544,079 output (18.5 percent) on 18 calls, against 9,588 to 45,667 in the last five lane rows.
- Fix: the check start reports and is judged by the head it ran at; accepted when no check start reports a commit other than the head over the next five runs and the check phase stays under 10 percent of output.
- Category: pipeline
- Added: 2026-11-21

### A head-form refusal restarts a start whose work is committed (status-winbar-tabs-b retro note 18, notes 12, 13)
- Location: `.claude/workflows/deliver-change.js` (the head check and escalation of a closing start).
- Why: a closing start whose commit 535eafb was already HEAD was refused for its head string's form, escalated, and restarted; the restart spent 18,885 output tokens on 13 calls and made 0 commits; 1 head-refused note across all run states.
- Fix: when the committed work is at HEAD and only the reported head's form differs, take the head from git and neither escalate nor restart; accepted when no head-refused note appears over the next five runs.
- Category: pipeline
- Added: 2026-11-21

### Advisory-only rounds and the closing start re-offer recorded advisories (review-trust-lows retro notes 12, 13)
- Location: `.claude/workflows/deliver-change.js` (the rework loop and the closing start); evidence for "### Advisory-only rounds chain on their own fixes (status-winbar-tabs-b retro note 16)", queued as backlog Pool 10 `closing-loop-fold`.
- Why: both rework rounds of review-trust-lows came from 0-blocking quality passes at 0d96eeaaa041 and d6685eb87eca; output 168,806 at the first check pass, then 263,524 and 326,416 (157,610, 39 percent of 404,092), turning the medium budget from under to over; the INSTRUCTION_RECORDS_RE advisory was offered 3 times and plan_apply's 4 times; closing closed 0 of 6; across the last 20 history rows the closing phase ran in 9 and closed advisories in 3.
- Fix: at most one fix round after the first check when no review blocks; an advisory already in the change's findings file reaches no later round or closing start; accepted when advisory-only runs show rework of 1 or less and no closing phase closes 0.
- Category: pipeline
- Added: 2026-11-21

### An advisory-only fix round reruns the full check (status-winbar-tabs retro note 8)
- Location: `.claude/workflows/deliver-change.js` (the rework loop), joining the queued closing-loop-fold.
- Why: 5 test-duplication advisories at 8573c94c2735 led to a second full check at d3d5af52bbae; check 45667/6 was 25.1 percent of 182,285 output tokens against syntax-tidy 4.6 and metrics-header-fix 5.6 percent, stages summing about 846 s.
- Fix: on a run whose only rework is an advisory fix touching tests and snapshots, rerun only the stages those paths need; accepted when the check phase stays under 10 percent of output tokens on such a run.
- Category: pipeline
- Added: 2026-11-21

### A records change sends quality advisories to fix rounds it cannot close (sprint-23-records retro note 9)
- Location: `.claude/workflows/deliver-change.js`, the records lane's quality and closing phases; joins the queued closing-loop-fold.
- Why: sprint-23-records ran 2 rework rounds and 1 closing start and closed 0 of 7 advisories, the quality phase 12270 of 63840 output tokens (19.2 percent); sprint-21-records rework 2 with 4 left, sprint-20-records 3 left.
- Fix: route a records change's advisories on groom output to its findings file without a fix round; accepted when the next three records runs show rework 0 from advisory-only rounds, no closing start, and quality under 8 percent of output, every advisory still recorded.
- Category: pipeline
- Added: 2026-11-21

### The benchmark runs on records changes with no carat file (sprint-23-records retro note 10)
- Location: `.claude/workflows/deliver-change.js`, the bench phase; complements the queued records-bench-skip.
- Why: 5144 of 63840 output tokens (8.1 percent) and 9 of 114 calls, allocations and rounds unchanged; sprint-22-records 5455/10 (11.6 percent), sprint-20-records 4548/5 (9.3 percent).
- Fix: a records change with 0 files under `carat/` records the bench as carried with 0 calls and its pull request Testing line says so.
- Category: pipeline
- Added: 2026-11-21

### The delivery prompts still name docs/backlog.md

- Location: `.claude/workflows/deliver-change.js:1670` (the scout area prompt) and `:1706` (the package prompt), each telling an agent never to read `docs/backlog.md`.
- Why: the file is gone, so the rule no longer covers the backlog folder in these prompts; backlog-per-file changed only the rules card line both copies share, and the read rules of every agent are `backlog-per-file-b`'s.
- Fix: in backlog-per-file-b, name `docs/backlog/` in both prompts beside the guard's folder rule.
- Category: pipeline
- Added: 2026-11-21

### Advisories a delivery cannot fix are offered again in each round and the closing start (tabs-only-dot retro note 14)
- Location: .claude/workflows/deliver-change.js, the advisory fix rounds and the closing start
- Why: the MODIFIED-scenario rename strict spec validation refuses was offered three times (quality notes 2 and 9, closing advisories 1 and 3) and the docs/backlog.md stale entries a delivery may not read twice (notes 7 and 10, closing 2 and 4); closing closed 0 of 5 here (3,813 output, 5 calls), and 0 in background-detect (0/5), review-trust-lows (0/6), sprint-23-records (0/7), sprint-24-records (0/7); 4 of 11 quality advisories of the run were of these two kinds. Near `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: an advisory the contributor reported unfixable with its reason, or one located in a file the lane may not edit, goes straight to the findings file and is not offered again; accepted when a run with such an advisory shows it offered once.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### Advisory-only rounds count as rework and push a medium change over its budget (tabs-only-dot retro note 15)
- Location: .claude/workflows/deliver-change.js, the fix rounds started on 0 blocking findings
- Why: the first check pass stood at 143,829 of 200,000 output, then two rounds with 0 blocking raised it to 259,891 and 298,918 (overrun notes 12, 13): 155,089 output (39.5 percent of 392,701) for README, design, test-comment, and findings edits; rework 3 on 0 blocking in review-trust-lows-b, 2 in sprint-24-records, 2 here; quality first pass 135/227, the weakest gate. Adds evidence to `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: a run whose every review reports 0 blocking records rework 0 and its advisories cost one closing start at most; accepted when such a run shows rework 0 and one closing start.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### An allocation regression is found only at the bench phase, after the check passed

- Location: the contributor's self-check and the check's stages before the bench phase (`make metrics-compare`, `.claude/workflows/deliver-change.js` bench phase); cmdline-editing note 3.
- Why: cmdline-editing first.bench=0, allocs.grep 774.4 to 779.9 blocking at 065185360ef4 after the check passed there; the rework round took output from 299,373 to 406,940 (107,567, 22 percent of 481,005) through implement, check, security, and bench again; the contributor ran the metrics stage without comparing; picker-styles-b also had bench:0 with rework 3; bench first pass 234/236.
- Fix: an allocation increase over main's recorded figures in any scenario fails before the bench phase; accepted when first.bench stays 1 and no rework round has an allocation cause across the next 10 runs.
- Category: pipeline
- Added: 2026-11-21

### The check reruns stages that cannot change and confirms passing stages at a sixth to a third of a run (review-in-openspec retro note 9, merged with facet-design-doc retro note 18)
- Location: .claude/workflows/deliver-change.js, the check phase; near the queued `check-at-head` (docs/queue-backlog.md Pool 11)
- Why: review-in-openspec's check took 121,585 of 724,443 output (16.8 percent) over 3 passes, all passing; contributor-tier-high 56,453 of 260,867 (21.6 percent); groom-evidence-only 119,742 of 338,328 (35.4 percent); facet-design-doc's docs-only fix rounds reran the whole check (72,939 output, 14 calls, 4 passes plus 1 rerun recorded at the base 6bb8f2af76ff, not the head 9478b94e2686), test-run 66 s and metrics 32 s though no file under carat/, bin/, test/, bench/, or tools/ changed after 9c0fcdac9b73; check first pass 218/230.
- Fix: accepted when, over the next three deliveries with first.check 1, the check stays under 8 percent of output with no stage failure CI finds that the check left out, a round touching only docs/ and openspec/ reruns no stage, and no check record names a commit other than the head it ran for.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### A non-blocking finding fixed in place still starts a full round (review-in-openspec retro note 10)
- Location: .claude/workflows/deliver-change.js, the fix round; near `closing-loop-fold`, folded into review-in-openspec at 3102188f23a3
- Why: review-in-openspec's round 2 fixed 1 advisory (a note's wording) and output went from 375,022 at the 9b4c63623c05 check pass to 653,549 at 8045d5552c96 (278,527, 38 percent of 724,443), over the large output budget 416,666; rework rounds 246 over 230 changes.
- Fix: accepted when, over the next three deliveries, metric.rework equals the rounds started by a blocking finding or a red CI, a non-blocking finding being fixed inside a running round or recorded.
- Category: pipeline
- Added: 2026-11-21

### check_runs is the contributor's own count
- Location: .claude/workflows/deliver-change.js extraRuns and the WORK field check_runs
- Why: self_fix sums the check runs the contributor reports; a start that misreports them skews the rework comparison, and nothing compares the count with the runner's verdicts.
- Fix: have tools/run_state.sh count the check runs per change (a counter the runner bumps at each start, never an agent) and let the workflow read that figure instead of the reported one.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### security Low (6): the checker trusts stage records the contributor can write itself
- Location: .claude/workflows/deliver-change.js:970 and :974 (claimFrom and backedCommit), tools/run_state.sh stage records (comments at lines 150-170, 339-349, and 643-651)
- Why: claimFrom and backedCommit back the head on the contributor's own reported pass, so the checker skips every stage with a passing stage record at that head. A contributor misled by text in the tree could edit tools/run_state.sh or a Makefile recipe in its working tree without committing, run `sh tools/run_state.sh check <change>` so the edited runner writes passing stage records at HEAD into build/pipeline/<change>.json, then restore the file with git restore; the base..HEAD diff still leaves tools/ untouched, so lane_facts reports machinery no and the checker skips the forged stages. Reported twice by the security review: the second pass found the comments (tools/run_state.sh 150-170 and 643-651, deliver-change.js 965-972, the design's Risks) now state this trust correctly, so the false claim is gone, but the behavior is unchanged. Impact is limited: CI reruns docs-lint, the builds, test-run, bench-budget, metrics, and tools-test, and main's merge gates rerun gates, which leaves diagnose resting on the contributor session's trust. Before this change, records at HEAD counted only when HEAD was the phase.check the workflow recorded.
- Fix: Stop trusting records an agent could have forged while keeping the speed-up: either the runner registers each run (its pid, start time, and HEAD) in a place outside the project the contributor's guard cannot reach, and the checker verifies it before skipping a stage; or a backed head skips only stages CI also runs, and diagnose and gates always rerun. Also widen the machinery test to the working tree at check time and to every commit since base, not only the base..HEAD diff.
none
- Also: tools/run_state.sh, Makefile
- Category: security
- Added: 2026-11-21

### A plan decision amending the brief does not reach the contributor (contributor-tier-high retro note 7)
- Location: .claude/workflows/deliver-change.js, the contributor's brief; docs/queue-backlog.md:11 at contributor-tier-high
- Why: its planner amended the brief (backtick the exception line's names, as queue_class needs), the contributor got only the brief, wrote bare names, and quality blocked at 43228fb; the fix round cost 157,564 output tokens (31,138 to 188,702); quality first pass 137/229, the weakest gate.
- Fix: hand the plan's amendments to the contributor with the brief; accepted when a run whose plan amends the brief has no quality-blocking finding on that amendment.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### An advisory confined to the change's own findings file costs a full round (contributor-tier-high retro note 8)
- Location: .claude/workflows/deliver-change.js, the fix round; near the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: contributor-tier-high's second round was a two-line wording fix in its findings file, output 188,702 to 218,283 (29,581), over the medium 200,000 output budget, with a check rerun at f95b02af0634, not the head; review-trust-lows-b rework 3, sprint-24-records rework 2, on 0 blocking.
- Fix: close such an advisory without a round; accepted when rework is unchanged and no check reruns. Merge into `closing-loop-fold` when groomed.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### The check phase spends a large output share on runs whose stages pass first time (contributor-tier-high retro note 9)
- Location: .claude/workflows/deliver-change.js, the check phase; tools/run_state.sh check
- Why: contributor-tier-high check 56,453 of 260,867 output (21.6 percent) for 12 calls with first.check 1; groom-evidence-only 119,742 of 338,328 (35.4 percent); check first pass 217/229.
- Fix: keep a first-pass check's output small; accepted when a run with first.check 1 spends at most 10 percent of its output in check.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### The merge phase cost grows with the merger's waiting, not with CI (border-vocabulary retro note 2)
- Location: .claude/workflows/deliver-change.js, the merger; evidence for the queued `merge-wait-bound` (docs/queue-backlog.md Pool)
- Why: border-vocabulary merge 142,172 of 518,649 output (27.4 percent), 18 calls, ci_wait_calls 10 at 11.4 CI minutes; the last 10 feature rows merge 18,467 to 85,414 output, ci_wait_calls 6 at 10.0 to 12.0 CI minutes.
- Fix: bound the wait; accepted when over the next 5 runs with CI at most 12 minutes the merge phase stays at or under 40,000 output tokens and ci_wait_calls at or under 6.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### A round for one test-only advisory reran every phase with unchanged results (border-vocabulary retro note 3)
- Location: .claude/workflows/deliver-change.js; evidence for the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: output at the check passes 204,095 then 348,268 (144,173, 27.8 percent of 518,649), rework 1 on 0 blocking, security 0 and bench equal on both passes; tabs-only-dot 155,089, groom-evidence-only 105,718, listchars-folds 107,710 on 0-blocking rounds.
- Fix: accepted when over the next 3 runs whose first reviews report 0 blocking, rework is 0 or the round costs under 10 percent of the run's output.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### A plan decision amending the brief does not reach the contributor (contributor-tier-high retro note 7)
- Location: .claude/workflows/deliver-change.js, the contributor's brief; docs/queue-backlog.md:11 at contributor-tier-high
- Why: its planner amended the brief (backtick the exception line's names, as queue_class needs), the contributor got only the brief, wrote bare names, and quality blocked at 43228fb; the fix round cost 157,564 output tokens (31,138 to 188,702); quality first pass 137/229, the weakest gate.
- Fix: hand the plan's amendments to the contributor with the brief; accepted when a run whose plan amends the brief has no quality-blocking finding on that amendment.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### An advisory confined to the change's own findings file costs a full round (contributor-tier-high retro note 8)
- Location: .claude/workflows/deliver-change.js, the fix round; near the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: contributor-tier-high's second round was a two-line wording fix in its findings file, output 188,702 to 218,283 (29,581), over the medium 200,000 output budget, with a check rerun at f95b02af0634, not the head; review-trust-lows-b rework 3, sprint-24-records rework 2, on 0 blocking.
- Fix: close such an advisory without a round; accepted when rework is unchanged and no check reruns. Merge into `closing-loop-fold` when groomed.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### The check phase spends a large output share on runs whose stages pass first time (contributor-tier-high retro note 9)
- Location: .claude/workflows/deliver-change.js, the check phase; tools/run_state.sh check
- Why: contributor-tier-high check 56,453 of 260,867 output (21.6 percent) for 12 calls with first.check 1; groom-evidence-only 119,742 of 338,328 (35.4 percent); check first pass 217/229.
- Fix: keep a first-pass check's output small; accepted when a run with first.check 1 spends at most 10 percent of its output in check.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### The merge phase cost grows with the merger's waiting, not with CI (border-vocabulary retro note 2)
- Location: .claude/workflows/deliver-change.js, the merger; evidence for the queued `merge-wait-bound` (docs/queue-backlog.md Pool)
- Why: border-vocabulary merge 142,172 of 518,649 output (27.4 percent), 18 calls, ci_wait_calls 10 at 11.4 CI minutes; the last 10 feature rows merge 18,467 to 85,414 output, ci_wait_calls 6 at 10.0 to 12.0 CI minutes.
- Fix: bound the wait; accepted when over the next 5 runs with CI at most 12 minutes the merge phase stays at or under 40,000 output tokens and ci_wait_calls at or under 6.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### A round for one test-only advisory reran every phase with unchanged results (border-vocabulary retro note 3)
- Location: .claude/workflows/deliver-change.js; evidence for the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: output at the check passes 204,095 then 348,268 (144,173, 27.8 percent of 518,649), rework 1 on 0 blocking, security 0 and bench equal on both passes; tabs-only-dot 155,089, groom-evidence-only 105,718, listchars-folds 107,710 on 0-blocking rounds.
- Fix: accepted when over the next 3 runs whose first reviews report 0 blocking, rework is 0 or the round costs under 10 percent of the run's output.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### The advisory-only settled round can no longer arise
- Location: .claude/workflows/deliver-change.js (settleFrom, settleRound, settledTesting, the alone branch of rounds and closeAdvisories)
- Why: fix in place and the closing loop now offer only security findings, and settleFrom returns no commit when a security finding is offered, so the review-lite path that stands on the earlier check, security, and bench passes is dead code with its tools-test cases.
- Fix: remove settleFrom, settleRound, settledTesting, settleAfter, settleAt, and the settle line of checkLines with their tools-test cases, or offer a non-security finding again; keep tools/run_state.sh settled while main's merge gates read settled_at.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### A run resumed across review-in-openspec drops its earlier quality advisories
- Location: .claude/workflows/deliver-change.js (seed)
- Why: seed no longer reads quality-advisory notes into the findings the package step hands over, so a delivery that ran a quality reviewer before this change merged and is resumed after it writes those advisories to no findings file; they stay only as run state notes.
- Fix: none needed once the deliveries in flight at the merge have finished; otherwise read quality-advisory notes into the backlog list in seed once more.
none
- Category: pipeline
- Added: 2026-11-21

### The merge phase costs more output than the check and security together

- Location: the merger start in `.claude/workflows/deliver-change.js`; comment-operator note 2.
- Why: merge 57,187 of 250,559 output (22.8 percent), 13 calls, ci_wait_calls 6, against check 9,886 and security 1,405; border-vocabulary 27.4 percent, listchars-folds 20.1, groom-evidence-only 16.7.
- Fix: wait for CI without an agent turn per poll; accepted when the merge phase stays under 10 percent of a run's output in each of the next five metrics rows, ci_wait_calls not higher, the merge still at the run state's squash commit.
- Category: pipeline
- Added: 2026-11-21

### Scout pack reuse and pruning never changed a decision

- Location: the scout phase in `.claude/workflows/deliver-change.js` and `tmp/scout/`; comment-operator note 3.
- Why: scout 43,172 output, 42 calls (17.2 and 21.3 percent) for 3 areas, 0 of 3 packs reused, 0 pruned, while `tmp/scout` holds 398 packs (every configuration pack stale); border-vocabulary 45 scout calls, grep-long-files 39, listchars-folds 39.
- Fix: remove the reuse step or make it reuse; accepted when the next five scouted runs average under 8 scout calls per area or record a reused pack, and `tmp/scout` holds no pack the reuse check would reject.
- Category: pipeline
- Added: 2026-11-21

### Records runs start advisory fix rounds and a closing start that change nothing (sprint-24-records retro note 11)
- Location: .claude/workflows/deliver-change.js, the advisory fix round and closing start of a sprint-N-records run
- Why: rework 2 on 0 blocking, 1 of 8 advisories fixed, the second fix round and the closing start made 0 commits (0 closed, 7 left); sprint-23-records rework 2, sprint-22-records 1, all with 0 blocking; the advisories target groom-written files or tools/, which a records change's Out of scope forbids. Near `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: a records run whose advisories all target groom-written files or tools/ starts no fix or closing contributor and sends them to its findings file; accepted when such a run records rework 0.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### The reviews phase dominates a records-only run (sprint-24-records retro note 12)
- Location: .claude/workflows/deliver-change.js, the reviews phase of a sprint-N-records run
- Why: reviews 27,661 of 68,824 output tokens (40.2 percent) and 31 of 101 calls on a diff of only docs/ records and the archived change; security 0 findings, quality 0 blocking at both passes.
- Fix: on a diff touching only docs/ records and the archived change, keep the reviews under 20 percent of output while the security review still runs on the committed diff; accepted when a records run shows it.
- Category: pipeline
- Added: 2026-11-21

### Records runs start advisory fix rounds and a closing start that change nothing (sprint-24-records retro note 11)
- Location: .claude/workflows/deliver-change.js, the advisory fix round and closing start of a sprint-N-records run
- Why: rework 2 on 0 blocking, 1 of 8 advisories fixed, the second fix round and the closing start made 0 commits (0 closed, 7 left); sprint-23-records rework 2, sprint-22-records 1, all with 0 blocking; the advisories target groom-written files or tools/, which a records change's Out of scope forbids. Near `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: a records run whose advisories all target groom-written files or tools/ starts no fix or closing contributor and sends them to its findings file; accepted when such a run records rework 0.
- Also: docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### The reviews phase dominates a records-only run (sprint-24-records retro note 12)
- Location: .claude/workflows/deliver-change.js, the reviews phase of a sprint-N-records run
- Why: reviews 27,661 of 68,824 output tokens (40.2 percent) and 31 of 101 calls on a diff of only docs/ records and the archived change; security 0 findings, quality 0 blocking at both passes.
- Fix: on a diff touching only docs/ records and the archived change, keep the reviews under 20 percent of output while the security review still runs on the committed diff; accepted when a records run shows it.
- Category: pipeline
- Added: 2026-11-21

### Packaging and the pull request text are two starts for one text (hidden-option retro)
- Location: .claude/workflows/deliver-change.js, the package and prtext contributor starts
- Why: hidden-option spent package 8,032 output tokens in 14 calls plus prtext 8,397 in 8, 16,429 output tokens (8.2 percent) and 22 of 172 calls (12.8 percent), with 0 findings appended; prtext's 8,397 is the highest of the last 11 feature rows (set-options 8,192, cmdline-editing 1,350); near backlog Pool 10 pr-claims.
- Fix: run the archive, the gated pr.md, and the push in one start when no finding is appended; accepted when that start finishes in at most 12 calls on the next three runs with no prtext round.
- Category: pipeline
- Added: 2026-11-22

### The scout re-packs lines the plan already cites (folded-row retro note 2)
- Location: .claude/workflows/deliver-change.js, the areas and scout phases; a near-same note of "### A one-area change still gets a scout pack (buffer-picker retro note 3, merge-gate-lows retro note 4)" and backlog queue Pool 14 `areas-in-plan`, `scout-prune`: merge into them.
- Why: folded-row scout 35,225/40 (23.6 percent of 149,066 output, 25.3 percent of 158 calls, 91 percent of implement's 44 calls) for 2 areas after the plan named `frame_presenter.rb:881` to `:883` and `themes.rb:226`, `:278`, `:330`, `:382`; set-options 28.7 percent, hidden-option 31.3 percent.
- Fix: no scout pack for an area whose edits the plan cites by path and line; accepted when, over the next 5 feature runs whose plan cites every edit, scout is at most 10 percent of output tokens and first-pass check stays 1.
- Category: pipeline
- Added: 2026-11-22

### A first-pass green CI still costs the merger 33,972 output tokens (folded-row retro note 3)
- Location: the merge phase of .claude/workflows/deliver-change.js; a near-same note of "### The merger spends about half its calls polling CI (buffer-picker retro note 4)" and backlog queue Pool 14 `merge-wait-bound`: merge into them.
- Why: folded-row merge 33,972/13 (22.8 percent of output), ci_wait_calls 6, CI green in 10 min; the same 13 calls cost 14,637 (colorscheme-command) and 16,600 (buffer-picker); border-vocabulary 142,172 (27.4 percent).
- Fix: a bounded, cheap wait for a green first CI; accepted when the next 5 runs with first.ci 1 and rework 0 keep merge at or under 17,000 output tokens in 13 calls or fewer.
- Category: pipeline
- Added: 2026-11-22

### The checker starts when every stage is carried from the contributor's pass (buffer-picker retro note 2)
- Location: .claude/workflows/deliver-change.js, the check phase; near backlog queue Pool 16 `check-at-head`, merge into it.
- Why: buffer-picker check 33,344/2 (9.0 percent of 369,656 output) with every stage skipped as passed at the same head; check 59,290/2, 24,047/2, 32,471/2 in cmdline-completion, set-options, colorscheme-command.
- Fix: no check agent when all stages are carried at the head; accepted when the next 3 such runs record no check agent tokens and first.check stays 1.
- Category: pipeline
- Added: 2026-11-22

### A one-area change still gets a scout pack (buffer-picker retro note 3, merge-gate-lows retro note 4)
- Location: .claude/workflows/deliver-change.js, the areas and scout phases; near backlog queue Pool 14 `scout-prune` and `areas-in-plan`, merge into them.
- Why: buffer-picker scout 37,539/22 (10.2 percent of output) for 1 area, implement still 74 calls; merge-gate-lows plan 20,300/13 relocated the lines, scout 18,783/13 packed the same area, the contributor relocated them again.
- Fix: no scout for one area or for lines the plan names; accepted when the next 3 one-area feature runs record no scout phase, implement at or under 83.5 calls, first.check 1.
- Category: pipeline
- Added: 2026-11-22

### The merger spends about half its calls polling CI (buffer-picker retro note 4)
- Location: the merge phase of .claude/workflows/deliver-change.js; near backlog queue Pool 14 `merge-wait-bound`, merge into it.
- Why: ci_wait_calls 6 of merge's 13 calls (46 percent) for a 12.0 min CI; 6 in 8 of the last 10 feature rows.
- Fix: wait outside the agent; accepted when the next 3 runs record ci_wait_calls 0 or 1 and merge at most 8 calls, first.ci unchanged.
- Category: pipeline
- Added: 2026-11-22

### Packaging spends two agent starts on a fixed sequence (merge-gate-lows retro note 3)
- Location: .claude/workflows/deliver-change.js, the package and prtext starts.
- Why: package plus prtext 23 of 128 calls (18.0 percent) in merge-gate-lows; 24 of 258, 32 of 241, 47 of 239, 48 of 297 in config-guards-b, pipeline-lows-a, contributor-harness, contributor-self-check.
- Fix: accepted when package and prtext take at most 10 calls together over the next 3 backlog runs, gates and ci first passes unchanged.
- Category: pipeline
- Added: 2026-11-22

### The checker starts when every stage is carried from the contributor's pass (buffer-picker retro note 2)
- Location: .claude/workflows/deliver-change.js, the check phase; near backlog queue Pool 16 `check-at-head`, merge into it.
- Why: buffer-picker check 33,344/2 (9.0 percent of 369,656 output) with every stage skipped as passed at the same head; check 59,290/2, 24,047/2, 32,471/2 in cmdline-completion, set-options, colorscheme-command.
- Fix: no check agent when all stages are carried at the head; accepted when the next 3 such runs record no check agent tokens and first.check stays 1.
- Category: pipeline
- Added: 2026-11-22

### A one-area change still gets a scout pack (buffer-picker retro note 3, merge-gate-lows retro note 4)
- Location: .claude/workflows/deliver-change.js, the areas and scout phases; near backlog queue Pool 14 `scout-prune` and `areas-in-plan`, merge into them.
- Why: buffer-picker scout 37,539/22 (10.2 percent of output) for 1 area, implement still 74 calls; merge-gate-lows plan 20,300/13 relocated the lines, scout 18,783/13 packed the same area, the contributor relocated them again.
- Fix: no scout for one area or for lines the plan names; accepted when the next 3 one-area feature runs record no scout phase, implement at or under 83.5 calls, first.check 1.
- Category: pipeline
- Added: 2026-11-22

### The merger spends about half its calls polling CI (buffer-picker retro note 4)
- Location: the merge phase of .claude/workflows/deliver-change.js; near backlog queue Pool 14 `merge-wait-bound`, merge into it.
- Why: ci_wait_calls 6 of merge's 13 calls (46 percent) for a 12.0 min CI; 6 in 8 of the last 10 feature rows.
- Fix: wait outside the agent; accepted when the next 3 runs record ci_wait_calls 0 or 1 and merge at most 8 calls, first.ci unchanged.
- Category: pipeline
- Added: 2026-11-22

### Packaging spends two agent starts on a fixed sequence (merge-gate-lows retro note 3)
- Location: .claude/workflows/deliver-change.js, the package and prtext starts.
- Why: package plus prtext 23 of 128 calls (18.0 percent) in merge-gate-lows; 24 of 258, 32 of 241, 47 of 239, 48 of 297 in config-guards-b, pipeline-lows-a, contributor-harness, contributor-self-check.
- Fix: accepted when package and prtext take at most 10 calls together over the next 3 backlog runs, gates and ci first passes unchanged.

none
- Category: pipeline
- Added: 2026-11-22
