### ci, main, and scan workflows pin their actions by tag
- Location: `.github/workflows/ci.yml` (`actions/checkout@v4`, `actions/cache@v4`), `.github/workflows/main.yml` (the same), `.github/workflows/scan.yml` (`actions/checkout@v4`)
- Why: review-trust-lows-b pinned only open-pr, the job holding PR_TOKEN; a moved tag still runs in the other jobs, which hold the cache and the scan's verdict, though no token beyond GITHUB_TOKEN.
- Fix: pin each by the commit its tag names (`git ls-remote` of the action's repository), the tag in a comment, and extend the open-pr pin test of `tools/tools_test.sh` to every workflow.
### A fork's pull request on the pushed commit still delays a first push's wait
- Location: `tools/open_pr.sh` `wait` (the several-numbers refusal)
- Why: git shows no head repository, so a fork that opens a pull request on the pushed commit before the run state records a number makes the wait refuse; the merger now refuses a fork's pull request, but the delivery stops until the number is set by hand.
- Fix: have the open-pr workflow publish the number it opened or edited where git can read it (for example a check run name on the head the wait reads through the merger), or let the merger resolve the number from the branch with the GitHub read tool.
### A merge-main carry keeps a review pass across a docs/goals.md commit (review-trust-lows quality, notes 1, 4)
- Location: `tools/run_state.sh:3673` (moved_change filters only RECORDS_RE), `tools/run_state.sh:1561` and `:1563` (settled_round's inline copy of the filter); queued as backlog Pool 11 `moved-change-instructions`.
- Why: #266 settled no pass across a docs/goals.md commit in reviewed_edits, but the merge-main carry still lets a review stand across a branch commit to an instruction record after the pass, the same stale-pass defect by another path; settled_round keeps its own copy of the outside_records filter #266 extracted.
- Fix: count INSTRUCTION_RECORDS_RE paths as changed in moved_change (or refuse the carry when moved_names holds one) and use outside_records in settled_round, keeping the docs/sprints.tsv line; accepted when a tools-test case of a carried pass across a docs/goals.md commit fails before the fix.

### Advisory-only rounds and the closing start re-offer recorded advisories (review-trust-lows retro notes 12, 13)
- Location: `.claude/workflows/deliver-change.js` (the rework loop and the closing start); evidence for "### Advisory-only rounds chain on their own fixes (status-winbar-tabs-b retro note 16)", queued as backlog Pool 10 `closing-loop-fold`.
- Why: both rework rounds of review-trust-lows came from 0-blocking quality passes at 0d96eeaaa041 and d6685eb87eca; output 168,806 at the first check pass, then 263,524 and 326,416 (157,610, 39 percent of 404,092), turning the medium budget from under to over; the INSTRUCTION_RECORDS_RE advisory was offered 3 times and plan_apply's 4 times; closing closed 0 of 6; across the last 20 history rows the closing phase ran in 9 and closed advisories in 3.
- Fix: at most one fix round after the first check when no review blocks; an advisory already in the change's findings file reaches no later round or closing start; accepted when advisory-only runs show rework of 1 or less and no closing phase closes 0.

### A plan's queues exceed the docs-lint queue budget at the package step (review-trust-lows retro note 14)
- Location: `.claude/agents/planner.md` step 5 and `tools/docs_lint.sh:61` (QUEUE_BUDGET 17969); queued as backlog Pool 13 `queue-fit`.
- Why: after plan-apply docs-lint failed with 18,149 lane-queue bytes against 17,969; the contributor trimmed the backlog queue in 88ae4ef and dropped a planner decision line; package took 27 calls, the most of the last 10 backlog rows (range 11 to 24).
- Fix: the plan is checked against the budget with the other lane's current queue before it is returned; accepted when no package step trims a queue after plan-apply and package calls stay at or under 22.
