# Backlog: tools/tools_test.sh

## The queue budget test writes its filler twice

- Where: the `queuesize` case of `tools/tools_test.sh` (line 1061 at 3a4db08), whose first `head -c 17369 /dev/zero` is cut again by a second `head -c` that sets the length. Quality advisory of `agent-inputs`.
- Why it matters: the redundant stage makes the one length that matters harder to read and to change with the budget.
- Fix outline: `head -c "$((17369 - $(wc -c < docs/queue.md)))" /dev/zero | tr '\0' x >> docs/queue.md`. Queued in `phase-shares`.
- Category: pipeline
- Added: 2026-11-04

## The workflow's verdict parsing has no test case

- Where: `tools/tools_test.sh` line 295 covers the routing only by grepping the `RERUN_WORDS` source line of `.claude/workflows/deliver-change.js`; `checkVerdict`'s parsing (the `run_state:` prefix, a refusal, a verdict at another commit) has no case. Quality advisory of `pipeline-durability`.
- Why it matters: a change to the verdict regexes could misroute a killed or superseded check into a fix round, or a failure into a rerun, without a test failing.
- Fix outline: extract the verdict regexes into a contract the shell test feeds sample verdict lines through.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-05

## The backup's kept base and a failed backup deletion have no case

- Where: `tools/tools_test.sh` line 443 (`branch_base` says a later merge of `origin/main` keeps the base, and `drop_backup` reports a failed deletion, but neither path is tested). Quality advisory of `backup-secret-scan`.
- Why it matters: a regression in either path passes `make tools-test`, and a wrong base lets the gates read too much or too little of the branch.
- Fix outline: add a backup after merging a new main commit (the base unchanged) and a `drop_backup` against an unreachable origin (exit 1, the message naming `abandon`).
- Category: pipeline
- Added: 2026-11-05

## A tools test case repeats the spent-over case

- Where: the case 'spent never stops a run' in `tools/tools_test.sh` (line 635 at `run-budgets`) repeats the exit-0 over case at line 629. Quality advisory of `run-budgets`.
- Why it matters: the duplicate adds run time and a second place to update without covering anything more.
- Fix outline: drop the case.
- Category: pipeline
- Added: 2026-11-06

## tools_test cases grep the workflow source instead of testing behavior

- Where: `tools/tools_test.sh:1741`, also 1694-1696, 1746-1747, 1752-1755, 1762-1763 (periodic quality at 5722559).
- Why it matters: the cases grep exact lines of `deliver-change.js`, `periodic-review.js`, and the agent files, so they pass whatever those lines do and fail on any rewording.
- Fix outline: move each decision (security pass with files left, merge stop without a checked sha, partial periodic record, worktree name) into a pure helper run through js, and drop the source greps.
- Category: pipeline
- Added: 2026-11-07

## The tools test's wait for the runner's stage fails silently

- Where: `tools/tools_test.sh` line 323 at d46ecff, the loop that waits for `stage.slow` to read `running` before superseding the runner. Quality advisory in `completion-docs`.
- Why it matters: after 20 tries the loop falls through, so a slow runner surfaces as an unrelated supersede failure.
- Fix outline: fail with a message naming the stage when `stage.slow` never reads `running`. Queued in `check-runner-safety`.
- Category: pipeline
- Added: 2026-11-07

## A tools test rebuilds the forged .git file by a round trip

- Where: `tools/tools_test.sh` lines 1261 to 1263 at the `pinned-main` change; quality advisory of `pinned-main`.
- Why it matters: a `cat`, `sed`, and `printf` round trip with a temporary file and `mv` does what one copy does, which makes the case harder to read.
- Fix outline: `rm -rf "$proj/tmp/.planted/.git"`, then `cp "$proj/tmp/.base/.git" "$proj/tmp/.planted/.git"`.
- Category: pipeline
- Added: 2026-11-09

## Tooling header, refspec, and compare message drift

- Where: `tools/tools_test.sh` line 2 (the header omits the tool-call caps section at line 1879 and the workflows' js cases); `tools/gates.sh` line 135 and `tools/agent_guard.sh` line 103 (the default fetch refspec defined twice); `tools/metrics.sh` line 105 (compare says the figures grew when a strict metric was only not measured), at 31919d9. Periodic quality. Queue items `run-budgets-tidy` (header, compare) and `merge-gate-tidy` (refspec, with merge-gate-integrity's open quality advisories).
- Why it matters: a header that misleads a reader, one rule in two places, and a failure message naming the wrong cause.
- Fix outline: list both sections in the header; define the refspec once in `tools/rules.sh` for the gates, the guard's copy under an equality case; say "grew or were not measured".
- Also: tools/gates.sh, tools/agent_guard.sh, tools/metrics.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-09

## The tools test leaves the MODIFIED scenario and archived attestation paths untested

- Where: `spec_file` in `tools/tools_test.sh` (line 1652 at the `implement-contracts-b` change) has no MODIFIED section, and no case attests a scenario in an archived proposal. Quality advisory of `implement-contracts-b`.
- Why it matters: the MODIFIED branch of `gate_scenarios` and the archive path of the stays attestation in `gate_docs` can break without a failing case.
- Fix outline: add a MODIFIED scenario to `spec_file` and a case whose attestation lives in an archived proposal under `openspec/changes/archive/`.
- Category: pipeline
- Added: 2026-11-09

## Leftovers of the commit hooks in the tools tests and the map

- Where: `tools/tools_test.sh:1754` (the case `pr_scan: the base's scanner reads a head that replaces the scanner` runs `$here/pr_scan.sh`, which already used the scanner beside it, so it passes without the change and proves nothing about `scan.yml`'s base checkout; the grep case after it does); `tools/tools_test.sh:846` (the review-due case still says it names the commit hooks and touches `.githooks/pre-commit`); `tools/tools_test.sh:1696` (about 20 lines build a stand-in Spinel repository and run the full `make toolchain` target to show `core.hooksPath` stays unset, which the grep case at 1718 already proves); `docs/codebase-map.md:48` (two parentheticals run together: `(a copy of rules.sh's) (core.hooksPath among them)`). Quality advisories of the `remove-commit-hooks` review.
- Why it matters: the case name describes hooks that no longer exist, the stand-in repository is speculative generality that costs test time, and the map line reads unlike its neighbor.
- Fix outline: rename the pr_scan case to state the contract it guards (`pr_scan.sh` reads the scanner beside itself, never the checkout's) or drop it; rename the review-due case to say it names a re-added `.githooks` file (or drop `[.]githooks/` from `REVIEW_AREAS` and the case); keep only the grep case at 1718 and remove the fakespinel and tooled setup and its case; merge the map's parentheticals into `(a copy of rules.sh's, core.hooksPath among them)`, as the `gates.sh` line above reads.
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at tools/tools_test.sh:1992

- Where: `tools/tools_test.sh:1992`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: sed s/^None$/None/ body.md is a no-op substitution used as a copy.
- Fix outline: cp body.md session.md.
- Category: pipeline
- Added: 2026-11-11

## pr-on-push quality advisory at tools/tools_test.sh:558

- Where: `tools/tools_test.sh:558`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: the open_pr cases prove no refusal of a branch with two new pr.md files, of a title with forbidden text at gate, or of a bad WAIT_STEP.
- Fix outline: add one expect case for each.
- Category: pipeline
- Added: 2026-11-11

### ci_scope.sh fallbacks have no tools test (`ci-time` quality advisory)

- Location: `tools/tools_test.sh:173`.
- Why it matters: the new fallbacks of `tools/ci_scope.sh` (no PR or HEAD_SHA, a green head that cannot be fetched, the GREEN_LOOKUPS limit) have no case.
- Fix outline: add an expect case for each, run=true.
- Also: tools/ci_scope.sh
- Category: pipeline
- Added: 2026-11-11

## records-once quality advisory at tools/tools_test.sh:1564

- Location: tools/tools_test.sh:1564, the rules: the records-only list is named once case.
- Why: the case packs two greps, a sed, and comma-joined printf output into one sh -c line that is hard to read and to diagnose on failure.
- Fix outline: two plain expects, one that grep -l of the literal path list over tools/*.sh names only rules.sh and one per reader that it names RECORDS_RE.
- Category: pipeline
- Added: 2026-11-12

### Drop the duplicated contributor size test (quality advisory)

- Where: `tools/tools_test.sh:2499`
- Why it matters: the contributor size test repeats the new docs_lint budget and greps its literal line, so a budget change must be made twice.
- Fix outline: rely on the docs-lint budget and drop the test, or keep only the size check.
- Category: pipeline
- Added: 2026-11-14

### Exercise the head tree and check-run filters in tools/tools_test.sh:172

- Location: tools/tools_test.sh:172, the ci_scope error cases (quality advisory, tests).
- Why: the new cases fail only the number query or every query (where head fails first), so the hex filter on head_tree and the digits filter on passed in the push branch are never exercised.
- Fix: add `err_scope tree.sha` and `err_scope check-runs` expectations asserting run=true.
- Category: pipeline
- Added: 2026-11-14

### Make each ci_scope expectation stand alone in tools/tools_test.sh:170

- Location: tools/tools_test.sh:170 (quality advisory, test independence).
- Why: `well_formed` reads `$work/scope-out` left by the preceding `err_scope` expectation, so each pair depends on its order.
- Fix: have one helper run `err_scope` and then check the file, so each expectation stands alone.
- Category: pipeline
- Added: 2026-11-14

### Drop the extra blank line in tools/tools_test.sh:188

- Location: tools/tools_test.sh:188 (quality advisory, style).
- Why: the added ci_scope block ends with a blank line before the existing one, leaving two blank lines before the green_pr comment where the file uses one.
- Fix: drop the extra blank line at 188.
- Category: pipeline
- Added: 2026-11-14

### Define merge_hook once in the guard hook tests

- Location: tools/tools_test.sh:1575 (quality advisory, duplication; also reported at 1562 against an earlier revision).
- Why: the merge-hook case inlines a copy of merge_hook (defined at 1647) with its own GIT_CONFIG_COUNT env instead of answered, so the two copies can drift.
- Fix: define merge_hook once above the hook cases, wrapped in answered, and call it from the merge-hook case.
- Category: pipeline
- Added: 2026-11-14

### Stop hardcoding the hook count in the main-resolution check

- Location: tools/tools_test.sh:1538 (quality advisory, brittle check; also reported at 1534).
- Why: the check that every hook line resolves main the same way hardcodes ^10 1$, so adding an agent or a hook fails it with no drift.
- Fix: assert only that the unique count is 1 and that the line count equals the number of command: lines under .claude/agents.
- Category: pipeline
- Added: 2026-11-14

### Check the hook runs before the empty TMPDIR assertion

- Location: tools/tools_test.sh:1597 (quality advisory, vacuous test).
- Why: the two hook runs before it discard their status and output, so if the hook failed before mktemp, or mktemp ignored TMPDIR, the empty directory still passes.
- Fix: wrap the two runs in expect with their 0 and 2 statuses, or assert the directory was used.
- Category: pipeline
- Added: 2026-11-14

### tools/tools_test.sh:2926 the wrapper status case never sees a failing status

- Where: tools/tools_test.sh:2926, the case named 'the wrapper keeps spinel's status'.
- Why: it only runs a stub that exits 0, so a wrapper that lost a failing status (spinel-doctor then reading a missing .c) would still pass (quality advisory, tests).
- Fix: add a stub run exiting non-zero and expect that status, plus diagnose-one and dev-build pass cases.
- Category: pipeline
- Added: 2026-11-15

## The docs-lint line-start marker case does not prove the line-start rule

- Location: tools/tools_test.sh:1829
- Why: the case 'a marker not at a line start does not count' rewrites the marker to 'An exception', which a substring match would not find either, so the line-start rule stays unproven.
- Fix: put the marker mid-line (for example 'Note: The user-approved exception ...') and expect the failure.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

## Static grep counts in tools_test prove text, not behavior

- Location: tools/tools_test.sh:2718
- Why: the static cases counting the word args and the agentType: contributor call site prove text, not behavior, and break on any new mention or call site.
- Fix: keep the startInput and contributorTask behavior cases and drop or narrow the grep counts.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

### Records-only case labels ci_scope under RECORDS_RE

- Location: tools/tools_test.sh:1862
- Why: the records-only case now counts ci_scope by its documentation call yet still prints it under the label RECORDS_RE, which ci_scope.sh no longer names.
- Fix: drop ci_scope from that list (documentation is in rules.sh, already counted) or label the readers by what they call.
- Category: pipeline
- Added: 2026-11-16

### Scout tools_test cases grep the workflow source text

- Location: tools/tools_test.sh:2790
- Why: 'no scout start without a needed area' and 'the area plan is measured apart' grep the workflow's source text, so a reformatting breaks them and a logic change can pass.
- Fix: drop the source-text greps, since the scoutTargets cases already prove the behavior, or test the phase through a stubbed measured.
- Category: pipeline
- Added: 2026-11-16

### Pack-currency tools_test cases match prose by regex

- Location: tools/tools_test.sh:2795
- Why: the pack-currency cases (2795, 2797, 2798) match the prose of PACK_CURRENT, the workflow source, and scout.md by regex, so a rewording breaks them and they prove no behavior, the pattern of the advisory at tools/tools_test.sh:2790.
- Fix: keep one case that PACK_CURRENT reaches the area-plan prompt through a stubbed agent, or accept them as wording guards and say so in a comment.
- Category: pipeline
- Added: 2026-11-16

### Sprint-8 tools_test cases grep scout and workflow prose

- Location: tools/tools_test.sh:2833, :2836, :2840, :2936 (sprint-8 review, quality); queued in `prose-grep-cases`.
- Why: the cases grep scout.md steps and contributorTask text; they break on rewording and prove no behavior.
- Fix: fold into `prose-grep-cases`, keeping the js-evaluated helper cases.
- Category: pipeline
- Added: 2026-11-16

### No plan-needed case heads the feature lane
- Location: tools/tools_test.sh:1360
- Why: every plan-needed case puts the head in docs/queue-backlog.md, so nothing proves a change heading docs/queue-feature.md is taken as written
- Fix: add an expect with the change as item 1 of docs/queue-feature.md printing not needed: NAME heads docs/queue-feature.md
- Also: docs/queue-backlog.md, docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-16

### Lane and merge-main refusals have no tools-test case
- Location: tools/tools_test.sh:1593; tools/run_state.sh:2330, :2365, :2383-2385
- Why: missing test: no case covers lane-open or lane-close over a non-worktree tmp/.lane-CHANGE, nor merge-main on a detached HEAD, on main, or with a dirty tracked tree.
- Fix: add one refusing expect case each.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### The not-due parseDue case uses review-due's old text
- Location: tools/tools_test.sh:3442
- Why: missing test: the case feeds parseDue 'for the next package step', which review_due no longer prints (now 'for its records change, sprint-N-records'), so the case no longer tracks the real output and a regression in parsing the new line goes unseen.
- Fix: use review_due's current not-due line in the fixture, or capture it from review_due itself.
- Category: pipeline
- Added: 2026-11-17

### checks-and-pr-lows test gap: the unstamped forged late-finding note is overwritten before it is checked
- Location: tools/tools_test.sh:986
- Why: the unstamped forged note.7 is overwritten by the following `state note history overrun`, numbered by the note count plus one (7), so the without-a-stamp case of late_findings is never exercised.
- Fix: set the forged notes after the overrun note or at numbers above the next note number.
- Category: pipeline
- Added: 2026-11-17

### tools_test pins whole prose sentences

- Location: tools/tools_test.sh:3493 (sweep, quality).
- Why: the planner and lanes cases grep -F whole sentences of planner.md and CLAUDE.md, so any rewording fails tools-test.
- Fix outline: pin each rule's key terms.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-17

### A lost runner's stage jobs keep running, and its test waits them out with a fixed sleep
- Location: tools/tools_test.sh:558, check_lost in tools/run_state.sh
- Why: the fixed `sleep 3` is timing-fragile and shows that check_lost leaves a hard-killed runner's stage jobs running, writing into the stage logs the next check reuses.
- Fix: have check_lost stop the lost runner's process group (setsid makes its pid the group id) and drop the sleep from the test.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### The sprint and parallel-check tests grep source lines and sleep fixed seconds (sprint-13 quality)
- Location: tools/tools_test.sh:3701, :472, :558.
- Why: the sprint tests grep exact lines of sprint-planning.js (const reviewed, const swept, const plan), so reformatting breaks them, and the parallel-check tests depend on 1 s and 4 s stage timings (sleep 3) and may flake on a loaded CI.
- Fix: test through exported helpers with js as the securityLine test does, and wait on the job status files or run state records. Queue item `prose-grep-cases`.
- Category: pipeline
- Added: 2026-11-17

### The planted-object case pins fsck's exact exit status (missing-test robustness)
- Location: tools/tools_test.sh:3441
- Why: the case expects exit status 3, the OR of git's internal fsck error bits (object plus reachability), which another git version may report differently, so the case can fail with the gate still working.
- Fix: assert that the line fails and its output names the mismatch, without the exact status.
- Category: pipeline
- Added: 2026-11-17

### The unpinned-git case proves the add, not that the planted gates ran (missing test)
- Location: tools/tools_test.sh:157 (the case an unpinned git would run the replaced gates past fsck)
- Why: the case sends the line's output to /dev/null and only cats the checked-out gates.sh, so it proves the worktree add followed the replace ref, not that fsck passed and the planted gates ran.
- Fix: assert the line's own output, sh -c "$2" 2>/dev/null expecting ^planted$, instead of the cat.
- Category: pipeline
- Added: 2026-11-17

### No case for a merged sha git cannot resolve
- Location: tools/tools_test.sh:311
- Why: the proposal counts a reported merged sha git cannot resolve (a mistyped hash) as a disagreement, but only a resolvable pushed head is tested, so a regression in that path would pass tools-test.
- Fix: add an expect running phase CHANGE merge merged with a hex value naming no commit and checking that the squash commit is recorded and the merge-disagreement note is written.
- Category: pipeline
- Added: 2026-11-17

### No case refuses a carried review when the moved record names another head
- Location: tools/tools_test.sh:860
- Why: missing test: the head check of the moved record behind a carried review has no case proving a record from an earlier head is refused.
- Fix: run moved to exit 0 at one head, commit, and expect review carried=1 at the new head refused.
- Category: pipeline
- Added: 2026-11-18

### No case pins the eight-character boundary of the bare assignment check
- Location: tools/tools_test.sh:2845
- Why: missing test: a workflow line such as 'id-token: write' in a .yml file, the most edited configuration kind, passing is untested, so a later edit of the value length could refuse it unnoticed.
- Fix: add a pass case for a seven-character value in config/app.yml beside the refused eight-character one.
- Category: pipeline
- Added: 2026-11-18

### Fix-in-place round test checks only a hand-built state
- Location: tools/tools_test.sh:3691
- Why: the case named for the fix-in-place round only checks passedAt on a hand-built state and inPlaceCheck, so the alone branch of rounds() (contributor fix start, continue, check and both reviews again) and the reviews() wiring of reviewFindings (security only in_change non-blocking, quality advisories) are unexercised; raised twice by the quality review, merged here.
- Fix: extract the end-of-round decision into a helper returning the next step and test it, or drop the claim from the case name.
- Category: pipeline
- Added: 2026-11-18

### 'workflow: a blocking round never settles' repeats other settle cases (review-lite quality advisory)

- Location: tools/tools_test.sh:4063
- Why: the rewritten case repeats 'workflow: findings in place ride with the blocking ones' (line 4084, inPlaceRound(true, ...) is 'with') and the alone case of line 4086, and its settleFrom element repeats line 4049, so it adds no proof and costs upkeep.
- Fix: drop it from settle_js (and inPlaceRound from settle_js's names) and cite the place_js cases in tasks.md 2.6
- Category: pipeline
- Added: 2026-11-19

### Quality handler note test only greps the literal text
- Location: tools/tools_test.sh:4303
- Why: the handler case only greps the literal note text, so the order (re-raises removed before misses are noted) and that an unmarked finding is not noted go unexercised.
- Fix: move the quality blocking split into a pure helper returning the raised and missed findings and test it through speed_js.
- Category: pipeline
- Added: 2026-11-19

### firstPassMiss cases duplicate each other
- Location: tools/tools_test.sh:4301
- Why: the firstPassMiss case at 4301 and the marker case at 4305 both prove a marked finding counts.
- Fix: fold the unmarked case of 4301 into the 4305 case and drop 4301.
- Category: pipeline
- Added: 2026-11-19

### Sprint-row fixtures still write docs/backlog.md

- Location: `tools/tools_test.sh`, the `printf '# Backlog\n' > docs/backlog.md` lines of the sprint-row and groom-refusal fixtures (four of them, near the "groomed sprint row" cases).
- Why: groom no longer reads the file, so the lines are inert fixture noise that suggests the old layout.
- Fix: drop them, or write `docs/backlog/_general.md` where a fixture needs a backlog file.
- Category: pipeline
- Added: 2026-11-21

### The check round's carry has no end-to-end workflow test
- Location: `tools/tools_test.sh` (the carried cases), `.claude/workflows/deliver-change.js` (`rounds`)
- Why: the tests prove `carryWanted`, `carriedRun`, the command, and the source order of the carry before the checker start, but `rounds` has no harness, so the wiring (the check record, budget note, and bench phase taking the carried result) is read, not run
- Fix: add a harness for `rounds` with a stub agent and `recordStart`, and assert no checker start and `phase.check` queued at the head when `carried` answers
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-23
