# Backlog: tools/open_pr.sh

## pr-on-push quality advisory at tools/open_pr.sh:43

- Where: `tools/open_pr.sh:43`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: BRANCH_RE takes no dot or nested slash while branch-push.yml fires on every type/** push, so a push of release/1.2.0 (the example in CLAUDE.md) turns open-pr red.
- Fix outline: have read print nothing to open and exit 0 for a branch it does not take, or narrow the branch-push filter to match.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-11

## pr-on-push quality advisory at tools/open_pr.sh:112

- Where: `tools/open_pr.sh:112`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: WAIT_STEP=0 passes the [0-9]{1,3} check and waited never grows, so wait polls origin forever.
- Fix outline: match [1-9][0-9]{0,2}.
- Category: pipeline
- Added: 2026-11-11

## pr-on-push quality advisory at tools/open_pr.sh:180

- Where: `tools/open_pr.sh:180`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: the read-back looks the pull request up by branch name (gh pr view "$branch") instead of the URL gh pr create printed, so a branch with an earlier pull request can compare the wrong one.
- Fix outline: keep the create output and pass that URL to both gh pr view calls.
- Category: pipeline
- Added: 2026-11-11

## pr-on-push quality advisory at tools/open_pr.sh:126

- Where: `tools/open_pr.sh:126`. Delivery review of `pr-on-push` (quality advisory) at a2d4b6c.
- Why it matters: wait counts only its sleeps toward SECONDS, not the up to 55 git ls-remote reads of origin, so a slow origin pushes the 540 s poll past the 600000 ms Bash timeout contributor.md:51 now sets and the tool kills it before its refuse message.
- Fix outline: stop on a deadline from date +%s, or lower MAX_WAIT to leave the reads room.
- Category: pipeline
- Added: 2026-11-11

### The branch types are written in three places (`sprint-1` review quality)

- Location: `tools/open_pr.sh:43` (BRANCH_RE), `tools/agent_guard.sh:101` (BRANCH), `.github/workflows/branch-push.yml:10` (branches).
- Why it matters: adding a type to one list silently breaks the open-pr path.
- Fix outline: a tools-test check that the three lists match, or one derived from another. Queue item `open-pr-tidy`.
- Also: tools/agent_guard.sh, .github/workflows/branch-push.yml
- Category: pipeline
- Added: 2026-11-12

### One title and body equality helper in open_pr.sh (quality advisory)

- Where: `tools/open_pr.sh:186`
- Why it matters: the title and body equality test is written twice, in the early exit and in the read-back loop, so the two can drift.
- Fix outline: one `same_text DIR` helper used by both.
- Category: pipeline
- Added: 2026-11-14

### open_pr.sh's wait step, double read, and branch pattern

- Location: tools/open_pr.sh:121, :82, :45 (sprint-4 sweep, quality).
- Why: WAIT_STEP=0 passes its check and wait polls forever; two gh pr view calls read title and body; BRANCH_RE copies agent_guard.sh:101 with no equality case.
- Fix: require a step from 1; one view call; a tools_test equality case.
- Category: pipeline
- Added: 2026-11-14

### checks-and-pr-lows correctness: open_pr wait can replace a recorded pull request number
- Location: tools/open_pr.sh:135
- Why: a single number on the pushed head is taken even when the run state already records a different pr, so a later push can overwrite the branch's pull request number with another one, a fork's included.
- Fix: when pr is recorded, accept only that number and keep waiting otherwise.
- Category: pipeline
- Added: 2026-11-17

### Scanner errors pass the text gates

- Location: tools/open_pr.sh:76, tools/gates.sh:208, :520, tools/docs_lint.sh:95, tools/scan_text.sh:82, :90 (sweep, quality).
- Why: the callers judge only the scanner's output, so an exit 2 with no output passes; --diff mode with a missing FILE scans nothing.
- Fix outline: fail on an exit other than 0 or 1, as pr_scan.sh does, and check each --diff FILE exists.
- Also: tools/gates.sh, tools/docs_lint.sh, tools/scan_text.sh
- Category: pipeline
- Added: 2026-11-17

### Pull request finding counts are hand-written and checked after the push (closing-loop retro 11)
- Location: `tools/open_pr.sh` (the body gate before the first push)
- Why: two counts were wrong in closing-loop's body (Changes "two non-blocking advisories" against 5 entries, 4 distinct; Testing "one advisory"), costing a body round and a second push: prtext 5,495 output tokens / 11 calls, pr_text_fixes 1, pushes 2.
- Fix: refuse before the first push a body whose finding counts differ from the run state's reviews or the findings file, or keep counts out of the body; accepted when the next runs record no prtext phase from a count.
- Category: pipeline
- Added: 2026-11-19

### Pull request finding counts are hand-written and checked after the push (closing-loop retro 11)
- Location: `tools/open_pr.sh` (the body gate before the first push)
- Why: two counts were wrong in closing-loop's body (Changes "two non-blocking advisories" against 5 entries, 4 distinct; Testing "one advisory"), costing a body round and a second push: prtext 5,495 output tokens / 11 calls, pr_text_fixes 1, pushes 2.
- Fix: refuse before the first push a body whose finding counts differ from the run state's reviews or the findings file, or keep counts out of the body; accepted when the next runs record no prtext phase from a count.
- Category: pipeline
- Added: 2026-11-19

### Gh pr list/view/edit --head BRANCH also match a fork's pull request of (sprint-20 sweep security Low (5), open_pr.sh:196)

- Location: `tools/open_pr.sh:196`
- Why: gh pr list/view/edit --head BRANCH also match a fork's pull request of the same branch name, so open-pr with PR_TOKEN can edit the fork's title and body instead of opening ours, or be blocked by it
- Fix: list with --json number,isCrossRepository, keep only same-repository pull requests, and view or edit by number
- Category: security
- Added: 2026-11-19

### A pull request's benchmark figure can compare different builds and sources

- Location: tools/open_pr.sh (the Testing section) and the run state's us_per_key (no grep scenario figure recorded)
- Why: the finder-grep-c body (retro 6) says 25.3 ms per key (dev budget build, bench-budget log) against about 45 ms before (release, the proposal's estimate), while its implement start measured 3.2 ms against main's 12.5 ms in release on the same scenario.
- Fix: record the grep scenario figure in the run state and let the Testing section cite only recorded run-state or stage-log figures, any before figure main's at the same build and scenario; accepted when a body citing an unrecorded timing is refused.
- Category: pipeline
- Added: 2026-11-20

### tools/open_pr.sh:132: WAIT_STEP=0 passes the [0-9]{1,3} check, and the wait loop (sprint-22 sweep quality)

- Location: `tools/open_pr.sh:132`
- Why: WAIT_STEP=0 passes the [0-9]{1,3} check, and the wait loop then never advances waited, so it spins until killed
- Fix: refuse 0, accepting 1 to 999, with a tools-test case
- Category: pipeline
- Added: 2026-11-20

### A fork's pull request on the pushed commit still delays a first push's wait
- Location: `tools/open_pr.sh` `wait` (the several-numbers refusal)
- Why: git shows no head repository, so a fork that opens a pull request on the pushed commit before the run state records a number makes the wait refuse; the merger now refuses a fork's pull request, but the delivery stops until the number is set by hand.
- Fix: have the open-pr workflow publish the number it opened or edited where git can read it (for example a check run name on the head the wait reads through the merger), or let the merger resolve the number from the branch with the GitHub read tool.
- Category: pipeline
- Added: 2026-11-21

### Pull request text claim check blocks a first pass (showtabline evidence for the package step's over-claim entry)

- Location: `tools/open_pr.sh` gate and the contributor's package mode; showtabline notes 6, 7; near-same as "### The package step's pull request text over-claims its own bookkeeping commits", to be merged into it.
- Why: showtabline pr-text-blocked round 1 (a table-driven claim true for 1 of 4 test files), prtext 4,347 output on 13 calls, pushes 2; pr_text_fixes in 6 of the 13 newest runs.
- Fix: as that entry; accepted when pr-text-blocked appears in at most 1 of the next 6 runs.
- Category: pipeline
- Added: 2026-11-21

### WAIT_STEP is matched by [0-9]{1,3}, so 0 is accepted at tools/open_pr.sh:138 (sprint-26 sweep quality, note 44)

- Location: tools/open_pr.sh:138
- Why: WAIT_STEP is matched by [0-9]{1,3}, so 0 is accepted and wait never advances waited, polling ls-remote past SECONDS forever
- Fix: match [1-9][0-9]{0,2}
- Category: pipeline
- Added: 2026-11-22

### open_pr.sh message skips the blank-line check at tools/open_pr.sh:186 (sprint-28 sweep quality, note 55)

- Location: tools/open_pr.sh:186, :215
- Why: message drops two lines without checking line 2 is blank, which read refuses.
- Fix: refuse in message too, or share one helper.
- Category: pipeline
- Added: 2026-11-22

### WAIT_STEP=0 passes the [0-9]{1,3} check, and the loop then at tools/open_pr.sh:137 (sprint-30 sweep quality, note 58)

- Location: tools/open_pr.sh:137
- Why: wait loop: WAIT_STEP=0 passes the [0-9]{1,3} check, and the loop then never advances waited, so wait spins until a pull request appears instead of ending after its seconds
- Fix: require [1-9][0-9]{0,2}
- Category: pipeline
- Added: 2026-11-23

### open_pr.sh matches is a whole-line match (grep -x) while at tools/open_pr.sh:77 (sprint-30 sweep quality, note 59)

- Location: tools/open_pr.sh:77
- Why: one clear way: open_pr.sh matches is a whole-line match (grep -x) while tools/agent_guard.sh:337 matches is unanchored, the same name with two meanings, and CHANGE_RE is copied in both files
- Fix: name the whole-line helper apart (whole_match) or give both one meaning
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-23

## security Low: a fork's lone pull request can be recorded by wait

- Location: `tools/open_pr.sh`, the `wait` case, the recorded-number preference when several pull requests share the pushed head.
- Why it matters: with the read-back gone, `wait` can record a fork's lone pull request on the pushed head. The merger's step 1 returns `stale` for it, but the recorded-number preference then keeps the fork's number even after this repository's own pull request appears, so the run stalls until `pr` is cleared.
- Fix outline: drop the recorded preference when the merger returns `stale`, or clear `pr` on a stale result.
- Category: security
- Added: 2026-11-23

## security Low (6): wait records a lone pull request without a scripted head-repository check (package, first)

- Location: tools/open_pr.sh:164 (wait records a lone pull request on the pushed head); tools/agent_guard.sh merge_tool.
- Why it matters: someone pushes the public branch commit to a fork and opens a pull request on it before open-pr opens ours, so wait records the fork's number. If the merger skips or misreads its step 1, it squash-merges that pull request with the fork's own title as commit_title. The tree is the same as ours (same sha), but the subject on main is controlled by the attacker. The merge hook checks expectedHeadSha, gated, and commit_message, not pullNumber or commit_title.
- Fix outline: add a check in tools/agent_guard.sh merge_tool that needs no gh. Refuse a merge whose pullNumber is not the run state's pr, and one whose commit_title is not the archived pr.md title followed by ' (#pr)'. Separately, clear pr in the run state when the merger returns stale, so a fork's recorded number does not stall the run.
- Also: tools/agent_guard.sh
- Category: security
- Added: 2026-11-23

## security Low (6): the merge hook does not check pullNumber or commit_title (package, second)

- Location: tools/open_pr.sh:164 (wait); tools/agent_guard.sh merge_tool, line 1121.
- Why it matters: the same attack as the entry above; wait records a lone pull request on the pushed head without a scripted check of its head repository, and the merge hook still checks only expectedHeadSha, gated, and commit_message, so a merger that skips its step 1 would squash-merge with a fork's title as the subject on main.
- Fix outline: in tools/agent_guard.sh merge_tool, with no gh needed, refuse a merge whose pullNumber is not the run state's pr, and one whose commit_title is not the archived pr.md title followed by ' (#pr)'. Add a tools-test case for each. Separately, clear pr in the run state when the merger returns stale.
- Also: tools/agent_guard.sh
- Category: security
- Added: 2026-11-23

### WAIT_STEP passes the check [0-9]{1,3} with 0, and then wait at tools/open_pr.sh:138 (sprint-32 sweep quality, note 52)
- Location: tools/open_pr.sh:138
- Why: WAIT_STEP passes the check [0-9]{1,3} with 0, and then wait with no matching pull request loops forever because waited never grows
- Fix: refuse a step of 0 (match [1-9][0-9]{0,2})
- Category: quality
