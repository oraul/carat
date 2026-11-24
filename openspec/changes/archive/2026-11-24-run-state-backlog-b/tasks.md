# Tasks

## 1. Fixes, each case failing at the base first

- [x] 1.1 test fails at the base, then fix: "The run state's writer has no lock beside the detached check runner" (line 9): a write refuses while a live process holds the run state's lock
- [x] 1.2 test fails at the base, then fix: "A lost check runner leaves its make running while a second one starts" (line 10): a check that finds its runner gone stops the processes the runner left
- [x] 1.3 test fails at the base, then fix: "Security: a stage's detached child can write after the escape scan (security Low (6), still present at package)" (line 137): a process a stage leaves running does not outlive the check
- [x] 1.4 test fails at the base, then fix: "Security: a stage-made worktree puts any local branch on the scan's skip list (security Low (6), reported twice, still present at package)" (line 148): a stage that forges a branch through a worktree it adds outside tmp/.lane- fails the check
- [x] 1.5 test fails at the base, then fix: "A write outside the check clone is detected but never reverted (security Low (4))" (line 178): a log planted in the main checkout's build/ from a lane is removed by the voided check
- [x] 1.6 evidence: already fixed at the base, a case that passes at both: "A records check is voided by build/dev/carat.timing escaping the check clone (sprint-27-records note 1)" (line 191)
- [x] 1.7 evidence: already fixed at the base, a case that passes at both: "A check is voided as escaped for a file the dev-build stage is declared to write (sprint-27-records note 1, security-escape)" (line 192)
- [x] 1.8 test fails at the base, then fix: "The escape scan's changed-path list reaches the terminal unfiltered (Low)" (line 203): the escaped-path list holds no escape byte

## 2. Behavior cases proving an earlier fix, failing at the commit before it

- [x] 2.1 test fails at the earlier commit, then green at the head: "A compile pass is cached whatever make command ran it" (line 4): a compile pass under one make command is not skipped under another
- [x] 2.2 test fails at the earlier commit, then green at the head: "dev-build's code key changes with test/ and bench/" (line 6): dev-build keeps its code key across a commit to test/ and bench/
- [x] 2.3 test fails at the earlier commit, then green at the head: "A link planted in the check clone's build directory survives" (line 22): a link a stage plants in build/ reaches no carry
- [x] 2.4 test fails at the earlier commit, then green at the head: "The runner's wait is longer than it says, in two copies" (line 23): the wait on a runner ends at its limit by the clock under a whole-second sleep
- [x] 2.5 test fails at the earlier commit, then green at the head: "Tests-only carry runs before the path scope in run_state.sh" (line 44): a stage recorded scoped is not carried across a tests-only commit, the scope deciding it again
- [x] 2.6 test fails at the earlier commit, then green at the head: "stages_stop does not record a passed compile stage as compiled" (line 87): a compile stage that passed while the check stopped is skipped on the same code
- [x] 2.7 test fails at the earlier commit, then green at the head: "jobs_refusal has two arms for one message and runs twice (sprint-13 quality)" (line 93): a runner refusing its CHECK_JOBS leaves the compile records as they were
- [x] 2.8 test fails at the earlier commit, then green at the head: "Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane" (line 143): lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref
- [x] 2.9 test fails at the earlier commit, then green at the head: "Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out" (line 144): a stage that switches the main checkout to another branch at the same commit fails the check
- [x] 2.10 test fails at the earlier commit, then green at the head: "Security: refs_view leaves refs/remotes/ out, and lane_open bases a new lane on a remote-tracking ref without fetching (security Low (5))" (line 145): lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref
- [x] 2.11 test fails at the earlier commit, then green at the head: "Quality: main_moved's ls-remote reaches the network with no prompt guard or time limit (quality advisory)" (line 146): the scan's ls-remote ends at its time limit
- [x] 2.12 test fails at the earlier commit, then green at the head: "Security: stages run with the real HOME and the scan ignores its executed files (security Medium (6))" (line 149): a stage that writes HOME's profile by an absolute path fails the check
- [x] 2.13 test fails at the earlier commit, then green at the head: "Quality: a tracked path holding a tab, newline, quote, or backslash is reported as untracked" (line 151): a tracked path holding a tab is not reported as an untracked file
- [x] 2.14 test fails at the earlier commit, then green at the head: "tools/run_state.sh:1143: [ -z "$HOME" ] under set -u (line 396) (sprint-22 review quality)" (line 154): a check with HOME unset still reads the references and fails on a forged one
- [x] 2.15 test fails at the earlier commit, then green at the head: "base-figures save checks only tracked files and untracked makefiles at tools/run_state.sh:2069 (sprint-30 sweep security Low (3), note 2)" (line 200): base-figures save refuses an untracked source file in the base

## 3. Not fixed here, with the reason

- [x] 3.1 record not fixed with the reason: "The run state header omits the compiled-KEY stage suffix" (line 5)
- [x] 3.2 record not fixed with the reason: "check_lost and check_wait re-read the run state and the pid file inline" (line 7)
- [x] 3.3 record not fixed with the reason: "The check verdict is read from a log read agents can write" (line 12)
- [x] 3.4 record not fixed with the reason: "Path-scope helpers split the stage-list comments in run_state.sh" (line 43)
- [x] 3.5 record not fixed with the reason: "Three path classifiers decide which stages run" (line 49)
- [x] 3.6 record not fixed with the reason: "A doubled blank line before check_wait (sprint-13 quality)" (line 94)
- [x] 3.7 record not fixed with the reason: "Shared state a check stage can still write without failing the check" (line 133)
- [x] 3.8 record not fixed with the reason: "The run-state comparison now leaves out every figure but the measurements (security Low (5), residual widened)" (line 136)
- [x] 3.9 record not fixed with the reason: "Security: a lane check accepts another lane's branch moved or its worktree files edited (security Low (6), reported three times, still present at package)" (line 147)
- [x] 3.10 record not fixed with the reason: "Quality: a check between the merger's lane-close and branch deletion fails as the references changed" (line 150)
- [x] 3.11 record not fixed with the reason: "In this sprint's diff (contributor-self-check). The checker now skips at tools/run_state.sh:1077 (sprint-26 review security Low (3), note 3)" (line 182)
- [x] 3.12 record not fixed with the reason: "duplication: backed_commit and check_stages (1082) each read phase.check and at tools/run_state.sh:681 (sprint-26 review quality, note 11)" (line 183)
- [x] 3.13 record not fixed with the reason: "the runner refuses a dirty tracked tree with its at tools/run_state.sh:1204 (sprint-26 sweep quality, note 13)" (line 184)

## 4. Evidence: already fixed, gone, or duplicate

- [x] 4.1 evidence: gone: "agent_hooks misses frontmatter keys that widen an agent's authority" (line 2)
- [x] 4.2 evidence: already: "An interrupted stage is recorded at the runner's head, not its start commit" (line 8)
- [x] 4.3 evidence: already: "A detached check runner outlives a stopped run and shares build/" (line 11)
- [x] 4.4 evidence: gone: "Recording merged deletes refs on origin from the generic key writer" (line 13)
- [x] 4.5 evidence: gone: "drop_backup joins the ref names by unquoted word splitting" (line 14)
- [x] 4.6 evidence: gone: "abandon reports no backup left when origin is unreachable" (line 15)
- [x] 4.7 evidence: gone: "The backup's base record outlives the backup" (line 16)
- [x] 4.8 evidence: gone: "The backup runs the branch's own gates" (line 17)
- [x] 4.9 evidence: gone: "A failed backup is retried by every start and never recorded" (line 26)
- [x] 4.10 evidence: duplicate: "pr-by-tag quality advisory at tools/run_state.sh:716" (line 30)
- [x] 4.11 evidence: gone: "Groom's listed check matches any archive name suffix (`sprint-planning` quality advisory)" (line 32)
- [x] 4.12 evidence: already: "Usage header splits review-due's description (`ci-time` quality advisory)" (line 36)
- [x] 4.13 evidence: already: "ci-stages may drop every step on fractional seconds (`ci-time` quality advisory)" (line 38)
- [x] 4.14 evidence: already: "merged_since reads only the last metrics row's merged commit" (line 52)
- [x] 4.15 evidence: gone: "sprint_state picks an exception past the fifth counted row" (line 53)
- [x] 4.16 evidence: duplicate: "plan_needed lists review runs by parsing ls output" (line 58)
- [x] 4.17 evidence: duplicate: "Review runs and full commits are looked up in several places of run_state.sh" (line 66)
- [x] 4.18 evidence: already: "A merge that fails on a moved main has no push path" (line 82)
- [x] 4.19 evidence: already: "Groom folds a findings file without a trailing newline as is" (line 83)
- [x] 4.20 evidence: already: "A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)" (line 85)
- [x] 4.21 evidence: already: "A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)" (line 86)
- [x] 4.22 evidence: already: "Folded backlog headings follow the previous entry with no blank line" (line 89)
- [x] 4.23 evidence: duplicate: "groom output needs a hand edit after each records run (sprint-12-records retro note 5)" (line 90)
- [x] 4.24 evidence: duplicate: "A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))" (line 91)
- [x] 4.25 evidence: duplicate: "The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))" (line 92)
- [x] 4.26 evidence: already: "The planner starts only to remove the delivered item (vim-line-commands-a retro 5)" (line 98)
- [x] 4.27 evidence: gone: "Records changes are judged against the small budget with the sprint reviews in their totals" (line 99)
- [x] 4.28 evidence: already: "moved compares the change's files through unquoted, magic-capable pathspecs" (line 100)
- [x] 4.29 evidence: gone: "Two lanes' exception lines against one uncounted exception (sprint-size-six retro)" (line 101)
- [x] 4.30 evidence: already: "The merger reports the branch head as the merged commit" (line 104)
- [x] 4.31 evidence: already: "The fold keeps a findings file's title as a second level-one heading" (line 106)
- [x] 4.32 evidence: already: "The fold adds headings with no blank line before them" (line 107)
- [x] 4.33 evidence: already: "The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)" (line 108)
- [x] 4.34 evidence: gone: "Budget line names the sprint key too narrowly" (line 109)
- [x] 4.35 evidence: already: "Fold adds a level-one heading per findings file" (line 112)
- [x] 4.36 evidence: already: "Folded headings lack a blank line before them" (line 113)
- [x] 4.37 evidence: already: "A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)" (line 114)
- [x] 4.38 evidence: already: "Groom's duplicate guard lets an unmarked security entry leave as a duplicate" (line 117)
- [x] 4.39 evidence: already: "Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))" (line 118)
- [x] 4.40 evidence: already: "Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))" (line 119)
- [x] 4.41 evidence: already: "Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)" (line 121)
- [x] 4.42 evidence: duplicate: "Two security entries stay open though #214 fixed them" (line 127)
- [x] 4.43 evidence: already: "HEADER names 24 columns (sprint-20 sweep quality, run_state.sh:484)" (line 131)
- [x] 4.44 evidence: already: "A check stage can forge its runner's job status files" (line 132)
- [x] 4.45 evidence: duplicate: "The checker's own figures stay writable by a stage during a check" (line 134)
- [x] 4.46 evidence: duplicate: "Correction: an edit of tools/run_state.sh by a stage is listed by the scan" (line 135)
- [x] 4.47 evidence: duplicate: "Security: a stage can forge its own run state's metric lines during a check (security Low (6), still present at package)" (line 138)
- [x] 4.48 evidence: duplicate: "Security: a stage can plant notes and closing phases in its own run state during a check (security Low (6), still present at package)" (line 139)
- [x] 4.49 evidence: duplicate: "The check-pass output budget line changed no decision" (line 140)
- [x] 4.50 evidence: already: "A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)" (line 153)
- [x] 4.51 evidence: already: "A concurrent lane's benchmark log fails another lane's check" (line 157)
- [x] 4.52 evidence: gone: "PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439" (line 159)
- [x] 4.53 evidence: already: "A lane's check fails on another lane's write into the main checkout's build/metrics" (line 160)
- [x] 4.54 evidence: duplicate: "groom folds the none/None lines of findings files (sprint-23-records retro note 11)" (line 164)
- [x] 4.55 evidence: gone: "named_history and named_since repeat the groom pathspec (sprint-24 review quality)" (line 165)
- [x] 4.56 evidence: duplicate: "plan-apply copies a plan older than the branch's queue" (line 170)
- [x] 4.57 evidence: duplicate: "An exception paragraph naming a change without backticks leaves it counted" (line 175)
- [x] 4.58 evidence: duplicate: "lane_of puts a docs change briefed to the feature lane in the backlog lane, so its history step writes a backlog file" (line 176)
- [x] 4.59 evidence: already: "The escaped verdict lets any write under the main checkout's build/ through (security Medium (5))" (line 177)
- [x] 4.60 evidence: already: "The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)" (line 179)
- [x] 4.61 evidence: duplicate: "The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)" (line 180)
- [x] 4.62 evidence: gone: "The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)" (line 187)
- [x] 4.63 evidence: duplicate: "The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)" (line 188)
- [x] 4.64 evidence: already: "tools/run_state.sh groom: security entries removed without a named fixing commit" (line 189)
- [x] 4.65 evidence: duplicate: "The check-pass output-token note fires in runs that end under the total budget (ui-groups retro note 3)" (line 190)
- [x] 4.66 evidence: already: "Stored figures of main trust the saving lane's measuring script" (line 197)
- [x] 4.67 evidence: duplicate: "The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)" (line 198)
- [x] 4.68 evidence: already: "merge_main pins only some of its git calls at tools/run_state.sh:4370 (sprint-31 review quality)" (line 201)

## 5. Queued to run-state-backlog-c, d, and e

- [x] 5.1 evidence: not fixed here, queued to run-state-backlog-e: "Agents leave scratch files in the repository root" (line 3)
- [x] 5.2 evidence: not fixed here, queued to run-state-backlog-e: "The run_state.sh bullet reads as if it listed every command" (line 18)
- [x] 5.3 evidence: not fixed here, queued to run-state-backlog-e: "run_state.sh became executable in run-budgets" (line 19)
- [x] 5.4 evidence: not fixed here, queued to run-state-backlog-d: "spent_line repeats budget_line's budget lookup" (line 20)
- [x] 5.5 evidence: not fixed here, queued to run-state-backlog-e: "A pipeline fix rode in the hover pull request" (line 21)
- [x] 5.6 evidence: not fixed here, queued to run-state-backlog-e: "A run_state.sh paragraph splits its Usage list" (line 24)
- [x] 5.7 evidence: not fixed here, queued to run-state-backlog-d: "The check-pass budget line projects 6 total tokens per output token" (line 25)
- [x] 5.8 evidence: not fixed here, queued to run-state-backlog-e: "drop_key repeats write_key's rewrite" (line 27)
- [x] 5.9 evidence: not fixed here, queued to run-state-backlog-e: "delivery-speed quality advisory at tools/run_state.sh:406" (line 28)
- [x] 5.10 evidence: not fixed here, queued to run-state-backlog-c: "delivery-speed quality advisory at tools/run_state.sh:1217" (line 29)
- [x] 5.11 evidence: not fixed here, queued to run-state-backlog-e: "Check clone's binary path not named in the map (late `pr-by-tag` quality advisory)" (line 31)
- [x] 5.12 evidence: not fixed here, queued to run-state-backlog-c: "Groom lets every copy of a duplicated finding go (`sprint-planning` quality advisory)" (line 33)
- [x] 5.13 evidence: not fixed here, queued to run-state-backlog-d: "plan-needed treats an unreviewed sprint plan as waiting (`sprint-planning` quality advisory)" (line 34)
- [x] 5.14 evidence: not fixed here, queued to run-state-backlog-d: "Sprint after a sixth merge reviews a change twice (`sprint-planning` quality advisory)" (line 35)
- [x] 5.15 evidence: not fixed here, queued to run-state-backlog-d: "Stale comment on who runs ci-stages (`ci-time` quality advisory)" (line 37)
- [x] 5.16 evidence: not fixed here, queued to run-state-backlog-d: "ci-stages step name can exceed 32 characters (`ci-time` quality advisory)" (line 39)
- [x] 5.17 evidence: not fixed here, queued to run-state-backlog-c: "records-once quality advisory at tools/run_state.sh:233" (line 40)
- [x] 5.18 evidence: not fixed here, queued to run-state-backlog-c: "records-once quality advisory at tools/run_state.sh:1586" (line 41)
- [x] 5.19 evidence: not fixed here, queued to run-state-backlog-c: "history and groom skip on records of a branch that never merges (sprint-2 sweep)" (line 42)
- [x] 5.20 evidence: not fixed here, queued to run-state-backlog-d: "The ci-stages secs filter is never run by a test" (line 45)
- [x] 5.21 evidence: not fixed here, queued to run-state-backlog-e: "merged_on_main repeats supported" (line 46)
- [x] 5.22 evidence: not fixed here, queued to run-state-backlog-e: "unmerged_list duplicates pending_list's loop" (line 47)
- [x] 5.23 evidence: not fixed here, queued to run-state-backlog-d: "Planner does not know the beyond-the-sprint marker" (line 48)
- [x] 5.24 evidence: not fixed here, queued to run-state-backlog-d: "The sprint exception membership test is written three times" (line 50)
- [x] 5.25 evidence: not fixed here, queued to run-state-backlog-d: "EXCEPTION_MARK names clash with the user-approved exception" (line 51)
- [x] 5.26 evidence: not fixed here, queued to run-state-backlog-d: "plan_needed lists run states differently from pending_list" (line 54)
- [x] 5.27 evidence: not fixed here, queued to run-state-backlog-d: "Unwrapped comment lines in run_state.sh" (line 55)
- [x] 5.28 evidence: not fixed here, queued to run-state-backlog-d: "planned_commits re-implements the run-state key parsing of read_key" (line 56)
- [x] 5.29 evidence: not fixed here, queued to run-state-backlog-d: "plan_needed and merged_since comments run past the comment wrap" (line 57)
- [x] 5.30 evidence: not fixed here, queued to run-state-backlog-d: "plan-needed wording says no change merged since though a merge planned before the review no longer counts" (line 59)
- [x] 5.31 evidence: not fixed here, queued to run-state-backlog-d: "Review-run listing and reviewed-commit resolution are repeated" (line 60)
- [x] 5.32 evidence: not fixed here, queued to run-state-backlog-d: "plan-needed needed line omits the later passing review condition" (line 61)
- [x] 5.33 evidence: not fixed here, queued to run-state-backlog-d: "run_state.sh header plan-needed line and plan_needed comment have over-long lines" (line 62)
- [x] 5.34 evidence: not fixed here, queued to run-state-backlog-d: "history_rows walks the whole rev-list on every call" (line 63)
- [x] 5.35 evidence: not fixed here, queued to run-state-backlog-d: "lane_of misses a queue item that estimate_of and exception_item find" (line 64)
- [x] 5.36 evidence: not fixed here, queued to run-state-backlog-d: "metrics_files breaks on a METRICS_PREFIX holding a space" (line 65)
- [x] 5.37 evidence: not fixed here, queued to run-state-backlog-c: "backlog-pick tries each backticked path twice" (line 67)
- [x] 5.38 evidence: not fixed here, queued to run-state-backlog-c: "Top-level docs findings never reach a batch" (line 68)
- [x] 5.39 evidence: not fixed here, queued to run-state-backlog-c: "No case pins a bare directory word known only by its files" (line 69)
- [x] 5.40 evidence: not fixed here, queued to run-state-backlog-e: "merge_main hides a merge failure that is not a conflict" (line 70)
- [x] 5.41 evidence: not fixed here, queued to run-state-backlog-e: "Concurrent lanes race on the shared origin/main ref lock" (line 71)
- [x] 5.42 evidence: not fixed here, queued to run-state-backlog-e: "lane_open and lane_close remove a worktree by different steps" (line 72)
- [x] 5.43 evidence: not fixed here, queued to run-state-backlog-d: "lane_of prints the shell's error for a missing queue file" (line 73)
- [x] 5.44 evidence: not fixed here, queued to run-state-backlog-e: "push --review-fix does not check that a review blocked" (line 74)
- [x] 5.45 evidence: not fixed here, queued to run-state-backlog-e: "The init usage line still says it refuses any merged run" (line 75)
- [x] 5.46 evidence: not fixed here, queued to run-state-backlog-e: "Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)" (line 76)
- [x] 5.47 evidence: not fixed here, queued to run-state-backlog-c: "history writes late findings to a findings file the records change folded" (line 77)
- [x] 5.48 evidence: not fixed here, queued to run-state-backlog-e: "groom documents CHANGE as optional though it dies without one" (line 78)
- [x] 5.49 evidence: not fixed here, queued to run-state-backlog-e: "lane_open checks the branch with a line-wise grep and a third copy of the pattern" (line 79)
- [x] 5.50 evidence: not fixed here, queued to run-state-backlog-c: "The package step appends the planner's findings twice" (line 80)
- [x] 5.51 evidence: not fixed here, queued to run-state-backlog-c: "plan-apply and history write into whatever checkout runs them" (line 81)
- [x] 5.52 evidence: not fixed here, queued to run-state-backlog-e: "The branch pattern and the trailer are spelled three times each" (line 84)
- [x] 5.53 evidence: not fixed here, queued to run-state-backlog-c: "Groom output needs a hand edit and draws the records runs' quality advisories" (line 88)
- [x] 5.54 evidence: not fixed here, queued to run-state-backlog-e: "squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))" (line 95)
- [x] 5.55 evidence: not fixed here, queued to run-state-backlog-e: "merged_at without a pr accepts any ancestor of HEAD (sprint-14 review and sweep quality)" (line 96)
- [x] 5.56 evidence: not fixed here, queued to run-state-backlog-e: "The security record keeps only the last review round (merge-record-check retro 7)" (line 97)
- [x] 5.57 evidence: not fixed here, queued to run-state-backlog-e: "A carried review trusts a moved record written by the branch's own run_state.sh" (line 102)
- [x] 5.58 evidence: not fixed here, queued to run-state-backlog-e: "moved carries when the merge keeps the change's side of a file main also edited" (line 103)
- [x] 5.59 evidence: not fixed here, queued to run-state-backlog-d: "The planner weighs quality-advisory notes the package step handled" (line 105)
- [x] 5.60 evidence: not fixed here, queued to run-state-backlog-d: "plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))" (line 110)
- [x] 5.61 evidence: not fixed here, queued to run-state-backlog-e: "reviewed-edits fails open when git diff fails (pipeline-diet quality)" (line 111)
- [x] 5.62 evidence: not fixed here, queued to run-state-backlog-e: "The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)" (line 115)
- [x] 5.63 evidence: not fixed here, queued to run-state-backlog-c: "Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)" (line 116)
- [x] 5.64 evidence: not fixed here, queued to run-state-backlog-c: "Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))" (line 120)
- [x] 5.65 evidence: not fixed here, queued to run-state-backlog-d: "exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)" (line 122)
- [x] 5.66 evidence: not fixed here, queued to run-state-backlog-c: "Groom leaves references to the findings files it removes (sprint-17-records retro)" (line 123)
- [x] 5.67 evidence: not fixed here, queued to run-state-backlog-d: "The token weighting prices a mid-tier start at the cheap tier's price" (line 124)
- [x] 5.68 evidence: not fixed here, queued to run-state-backlog-c: "Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)" (line 125)
- [x] 5.69 evidence: not fixed here, queued to run-state-backlog-e: "settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)" (line 126)
- [x] 5.70 evidence: not fixed here, queued to run-state-backlog-c: "SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)" (line 128)
- [x] 5.71 evidence: not fixed here, queued to run-state-backlog-e: "Extra push allowed by push --pr-text without a blocked text review" (line 129)
- [x] 5.72 evidence: not fixed here, queued to run-state-backlog-e: "The new --pr-text push kind accepts any commit, as long as a recorded (sprint-20 review security Low (3), run_state.sh:1330)" (line 130)
- [x] 5.73 evidence: not fixed here, queued to run-state-backlog-d: "An advisory-only fix round counts as rework and reruns every stage and review" (line 141)
- [x] 5.74 evidence: not fixed here, queued to run-state-backlog-d: "review-due no longer bounds uncounted merges" (line 142)
- [x] 5.75 evidence: not fixed here, queued to run-state-backlog-c: "Findings of grep-long-files after its package step" (line 152)
- [x] 5.76 evidence: not fixed here, queued to run-state-backlog-c: "history names the run state file as the lane file it appended to" (line 155)
- [x] 5.77 evidence: not fixed here, queued to run-state-backlog-d: "plan-needed names only the first failing review while merged_since clears every one before the planner's time" (line 156)
- [x] 5.78 evidence: not fixed here, queued to run-state-backlog-c: "groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)" (line 158)
- [x] 5.79 evidence: not fixed here, queued to run-state-backlog-e: "A security review after a quality-only fix reads the whole branch again" (line 161)
- [x] 5.80 evidence: not fixed here, queued to run-state-backlog-c: "plan-apply copies a planned goals.md after the security review" (line 162)
- [x] 5.81 evidence: not fixed here, queued to run-state-backlog-c: "groom folds none/None placeholder lines from findings files" (line 163)
- [x] 5.82 evidence: not fixed here, queued to run-state-backlog-c: "SPRINT_HEADER is never read (sprint-24 sweep quality)" (line 166)
- [x] 5.83 evidence: not fixed here, queued to run-state-backlog-c: "backlog-move's mismatch refusal has no test" (line 167)
- [x] 5.84 evidence: not fixed here, queued to run-state-backlog-c: "A refused filing leaves the entries filed before it in the folder" (line 168)
- [x] 5.85 evidence: not fixed here, queued to run-state-backlog-c: "plan-apply overwrote the lane queue with a plan older than the branch's queue" (line 169)
- [x] 5.86 evidence: not fixed here, queued to run-state-backlog-d: "A change named only in a lane exception line resolves to the wrong lane (facet-design-doc retro note 16)" (line 171)
- [x] 5.87 evidence: not fixed here, queued to run-state-backlog-c: "Plan notes reach the findings file twice (facet-design-doc retro note 17)" (line 172)
- [x] 5.88 evidence: not fixed here, queued to run-state-backlog-d: "self_fix has no history column" (line 173)
- [x] 5.89 evidence: not fixed here, queued to run-state-backlog-d: "An exception paragraph naming a change without backticks leaves it counted in the sprint" (line 174)
- [x] 5.90 evidence: not fixed here, queued to run-state-backlog-c: "backlog-move is a one-shot migration left in run_state.sh (sprint-25 review quality)" (line 181)
- [x] 5.91 evidence: not fixed here, queued to run-state-backlog-c: "The planner's sprint queues reach a records change failing the docs-lint queue check (sprint-26-records retro note 4)" (line 185)
- [x] 5.92 evidence: not fixed here, queued to run-state-backlog-d: "Head-form notes record a head git confirms (folded-row retro note 4, notes 1 and 5)" (line 186)
- [x] 5.93 evidence: not fixed here, queued to run-state-backlog-c: "A carrying delivery that never merges strands the sprint plan" (line 193)
- [x] 5.94 evidence: not fixed here, queued to run-state-backlog-c: "groom-proof checks a carrier's plan line against evidence the carrier controls" (line 194)
- [x] 5.95 evidence: not fixed here, queued to run-state-backlog-c: "groom's fixed proof takes a commit of the carrying branch (sprint-29 review security Low (4))" (line 195)
- [x] 5.96 evidence: not fixed here, queued to run-state-backlog-c: "groom and groom_proof copy the fixed proof (sprint-29 review quality)" (line 196)
- [x] 5.97 evidence: not fixed here, queued to run-state-backlog-c: "groom_row's untracked sprint marker (sprint-14 review security Low (3) and quality)" (line 199)
- [x] 5.98 evidence: not fixed here, queued to run-state-backlog-d: "Overrun notes repeat within a run (explorer-rows retro 14)" (line 202)
- [x] 5.99 evidence: not fixed here, queued to run-state-backlog-e: "lane-open leaves a real directory at a shared-state path unchecked at tools/run_state.sh:4354 (sprint-32 security Low (4))" (line 204)
- [x] 5.100 evidence: not fixed here, queued to run-state-backlog-e: "merge_main aborts a conflicted merge and then tells the contributor at tools/run_state.sh:4430 (sprint-32 sweep quality, note 14)" (line 205)
- [x] 5.101 evidence: not fixed here, queued to run-state-backlog-e: "merge_main repeats the identity and message flags (-c user.name=Claude -c at tools/run_state.sh:4403 (sprint-32 sweep quality, note 53)" (line 206)
- [x] 5.102 evidence: not fixed here, queued to run-state-backlog-e: "merge_main runs git with the global configuration and hooks again" (line 207)

## 6. Quality review

- [x] 6.1 Wrap the comments the change touched at 80 columns (fixed)
- [x] 6.2 Two writers can both retake a stale run state lock (recorded in docs/findings/run-state-backlog-b.md)
- [x] 6.3 The removal of a planted file may delete a concurrent lane's build file (recorded in docs/findings/run-state-backlog-b.md)
- [x] 6.4 A stage that starts its own session leaves the group kill (recorded in docs/findings/run-state-backlog-b.md)

## 7. Review round: the four security Lows, each case failing at the earlier commit first

- [x] 7.1 test fails at the earlier commit, then fix: security Low (5), runner_group_stop signals a pid read from check.pid unvalidated: a pid file naming pid 0 does not make the check signal its own process group (valid_pid, applied in both pid reads and in runner_group_stop)
- [x] 7.2 test fails at the earlier commit, then fix: security Low (4), escaped_revert reads paths one per line: a planted name holding a newline lists as one removal and leaves the file its second line names; the voided check lists each removal in its log; the removal checks the directory with cd -P under the main checkout's build/ and the change time against escape_since
- [x] 7.3 test fails at the earlier commit, then fix: security Low (5), new_lane_branches matches any path ending in tmp/.lane-NAME: a stage that forges a branch through a worktree at another checkout's tmp/.lane-NAME fails the check, and a lane at the main checkout's tmp/.lane-NAME leaves it passing
- [x] 7.4 test fails at the earlier commit, then fix: security Low (3), state_lock takes over a stale lock without an atomic step: a waiter does not take a lock a live process retook after it read the dead owner (rename aside, recheck the owner, link back)

## 8. Review round: the lock's takeover window

- [x] 8.1 test fails at the earlier commit, then fix: security Low (2), state_lock's rename-and-link-back takeover leaves a narrow window: the lock is a directory made with mkdir holding a pid file, a stale one taken over by renaming it aside and checking its owner again, released only while its pid file names this process, and the rewrite renamed in only while the lock is held; cases: a live holder refuses, a dead one's lock is taken over, a lock moved aside that proves live is back with its owner, a writer whose lock a third writer took in the gap refuses and leaves that lock and the record
- [x] 8.2 Two writers can both retake a stale run state lock (task 6.2): closed by 8.1
