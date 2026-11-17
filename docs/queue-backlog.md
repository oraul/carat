# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 16

## Pool

1. `explorer-tidy` (T6 with a correctness bug, estimated medium, pushed back 2, reason: backlog-pick order): the tree cursor drifts when follow expands above it; 9 explorer tidy entries.
2. `check-runner-safety` (T1 pipeline defect, security Medium (6), estimated medium, pushed back 17, reason: not in backlog-pick's first two batches): `tools/run_state.sh:639`, Low (4) `:778`.
3. `ci-trust-gaps-b` (T1 pipeline defect, security Lows (6), (5), estimated medium, pushed back 1): CI runs the branch's `tools/ci_scope.sh` (`.github/workflows/ci.yml:54`, `:58`); the check clone shares a writable toolchain (`tools/run_state.sh:571`). Accepted when tools-test cases show a branch's scope script ignored and a stage's toolchain change caught. Backlog: "### CI runs the branch's own scope script (security Low (6))", "### The check clone shares a writable toolchain (security Low (5))".
4. `ci-trust-gaps-c` (T1 pipeline defect, security Lows (5) to (3), estimated medium, pushed back 1): open-pr counts and edits a fork's same-named or same-sha pull request with PR_TOKEN (`tools/open_pr.sh:118`, `:180`, `:190`, `:196`; `.github/workflows/open-pr.yml:39`); the sprint report misreads the sweep (`.claude/workflows/sprint-planning.js:270`). Backlog: "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)", "### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))", "### The sprint report misreads the sweep", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39".
5. `review-scope-pins` (T1 pipeline defect, Medium (4), estimated medium, pushed back 1, split at its start): "## A security review after a quality-only fix reads the whole branch again", "## The review continuations run one after the other", "## Security Lows of the periodic review at 186ddfb", "## A security review stays current after later instruction-file commits".
6. `toolchain-clean-scope` (T1 pipeline defect, data loss, estimated small, pushed back 1): `Makefile:203`, `README.md:21`.
7. `sprint-security-b` (T1 pipeline defect, security Lows (6) to (3), estimated medium, pushed back 1): `tools/gates.sh:131` groom_row, `run_state.sh:1581` merged_at; "### Groom removes security entries without proof of a fix (`sprint-planning` security Low (6))", "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### Groom's fixed check accepts any ancestor commit (`sprint-planning` quality advisory)".
8. `motions-search-tidy-b` (T4 run time, estimated medium): sentence motions about 96 ms per key on 100,000 lines (`carat/domain/motions.rb:418`); incsearch about 1.5 s per key (`preview_search.rb:48`); `search.rb:110` ASCII length charge; one-character slices.
9. `motions-search-tidy-c` (T6 tidy, estimated medium): motions take the whole EditorState; the `:noh` row (`docs/compatibility.md:310`); sprint-14 sweep tidy of area 6; "### Four sites compile a search against the last substitute by hand (sprint-15 review quality)", "### DelimitedPattern.typed is an alternate constructor not named from_x (sprint-15 review quality)".
10. `records-budget-scope` (T1 pipeline defect, estimated small): 5 of 5 records rows read over 500,000 with sprint-planning's reviews counted (sprint-14 1,973,945 on 32,743 output; sprint-15 1,215,649 on 39,590, its overrun note).
11. `package-advisory-edit` (T1 pipeline defect, estimated small): the package step edits reviewed files and queues plan-apply overwrites: motions-search-tidy 16,259/22 and gates_failed 1; record-squash-commit 38,843/17, its queue edits replaced (median about 8,600/16).
12. `lint-own-queue-paths` (T1 pipeline defect, estimated small): docs-lint failed ruby-structure-remove's check on 2 paths its own queue item named, rework 1.
13. `plugin-host-tidy` (T6, estimated small, batch 2 part b): "## PluginUi keeps each segment in three structures", "## Four comments of bars break their file's wrap width", "## WindowRequests#in_window keeps a dead local and an unobservable restore", "## move_float bypasses the float use cases".
14. `plugin-host-move` (T6, estimated large, batch 2 part c, split at its start): "## The plugin host keeps many-method classes in use_cases".
15. `plan-skip-placed`, `scout-pack-reuse`, `merge-cap-ci-wait` (T1 pipeline efficiency, estimated small each, secret-patterns retro notes 5 to 7): the planner ran on a placed, estimated first item and changed no decision (plan 11,077/12, 8.7 percent of output), accepted when such a delivery records planned=0 while plan-apply still removes the item; a current area pack was scouted again for one missing location (scout 42,854/20, 33.6 percent of output, 1.34 times implement), accepted when such a run spends under 15 percent on the scout; a first-pass green CI overran the medium merge cap (16 calls of 14, ci_wait_calls 6, CI 8.4 min), accepted when the next three such medium runs stay at or under the cap with no merge overrun note.

## Decisions

- Security first clear (T0): 0 `review.periodic` findings in the 1 pending run, secret-patterns security high 0, medium 0, low 1; this item's Medium (4) and Low (5) are under confidence 8; nothing in `security_first`.
- `git-signs-transport` delivered as written and removed (T3 security Low (5) and Medium (4), pushed back 3, drawn by aging): Sprint 16's backlog lane drained, 0 of 2 left after secret-patterns merged at 95bf2e0, waiting for /sprint.
- Estimated medium, no size up (T3, size rule): comparable medium backlog rows record-squash-commit 815,807 in 37.0 min, check-parallel 849,706 in 44.1, ci-trust-gaps 1,020,093 in 47.6, secret-patterns 1,092,903 in 40.5; of the last two lane runs only sprint-15-records went over (1,215,649 on a small budget).
- Kept whole (T3, size rule): 1 map area (15, plugin host and API), 4 backlog entries, the two float parts one ownership rule (`own_float_tab`), so 2 independently testable rules, under goals' about four fixes.
- 0 `tools/rules.sh` edits (T3): the item names git_signs and plugin host files only.
- Retro notes 5, 6, 7 of secret-patterns to pool item 15 (T1 pipeline efficiency): plan 8.7 and scout 33.6 percent of output, merge 16 calls of 14; outside the sprint, a pipeline item only for a defect.
- Overrun notes folded (T1): sprint-15-records 1,215,649 against 500,000 into `records-budget-scope`; merge 16 calls of 14 into `merge-cap-ci-wait`.
- Quality notes 1 to 4 of secret-patterns not placed (T6): advisories its run handled already.
- Pool otherwise unchanged, 0 push-backs (T3): this delivery was first and passes none of the 14 pool items.
