# Backlog: docs/goals.md

## lh time per key rose 26% at window-navigation-and-scroll

- Where: the `review.bench` record of `window-navigation-and-scroll` (lh median 11.7 to 14.8 microseconds per key, allocations 27.0 unchanged); no code location is known. Advisory of the periodic quality review at 66fd52b.
- Why it matters: goal 3 of `docs/goals.md` watches time per key; a rise reported as not blocking and never measured again may hide a cost of the prefix wait or the `breaks_insert` check.
- Fix outline: run `make bench SCENARIOS=lh` on `main` and on its parent several times on one pinned core; if the rise holds, profile `lh` with `make profile` and fix or record the cause.
- Category: pipeline
- Added: 2026-11-03

## The calibration reasons miscount the cheap-tier starts

- Where: `docs/goals.md` line 34, the calibration's reasons. Quality advisory in `agent-calibration` (reported at lines 187 and 34 across its rounds).
- Why it matters: the reasons say "the four with an agent file on the cheap tier" after listing six mechanical starts of which only three (checker, benchmark, merger) have an agent file; the fourth cheap start, the scouts, is not in the list, so the rule misreads.
- Fix outline: say "the three with an agent file", or add the scouts to the list of mechanical starts.
- Category: pipeline
- Added: 2026-11-07

## The calibration rule counts CI reds caused outside the change

- Where: the Calibration rule of `docs/goals.md`; the retrospective of `parameter-info` (#78). The plan of `discoverability` dropped `scout-effort-revert` by this reading; the goals text waits for the user.
- Why it matters: low-effort scout rows #74 to #78 passed CI first 3 of 5, both reds a timed runner case (`check-runner-safety`), 5 of 5 counting own-diff reds, rework 7 against 7; the literal rule would revert a move that did no harm.
- Fix outline: count only first-pass reds whose recorded cause is in the change's own diff, with the cause recorded in the run state.
- Category: pipeline
- Added: 2026-11-09

## Findings of design-principles at review

- Quality, docs currency, docs/goals.md:27: the T0 scope is inconsistent; goals keeps only T0 security fixes outside the sprint mix while CLAUDE.md:206 (T0 exempt from both) and .claude/agents/planner.md:35 (T0 exempt) exempt every T0 item, a red main or a crash too, so a T0 crash fix counts in the mix by one text and not by the other. Fix: say "T0 items stay outside the mix and always go first" in docs/goals.md:27, or narrow the other two to security.
- Quality, docs accuracy, .claude/agents/planner.md:35: "three features and two fixes, ... a decision citing 3 features, 2 fixes, ...; make docs-lint checks it" reads as if docs-lint checks the mix, but tools/docs_lint.sh:152 counts only pipeline items and nothing enforces the mix (the change's design.md Risks). Fix: write "make docs-lint checks the pipeline count, not the mix".
- Quality, wording, .claude/agents/planner.md:22: "at most one fix a pipeline change" is ungrammatical and ambiguous, as if a pipeline change had to be a fix. Fix: "three features and two fixes, a pipeline change, at most one, counting as a fix, T0 exempt".
- Quality, rule gap, docs/goals.md:27: the fixed mix of three features and two fixes, and the planner's sprint mode at .claude/agents/planner.md:35, has no rule for a pool with fewer than three ready features, beside the older "when no feature is ready, the next non-feature item runs". Fix: add one clause, "with fewer features ready, fixes fill the slots and a decision says so".
- Quality, accuracy, openspec/changes/archive/2026-11-15-design-principles/proposal.md:29: Impact says four sentences repeating sections 2, 9, and 13 are shortened or removed, but the diff trims six places in docs/architecture.md, and the dropped CRuby 4.0.4 benchmark baseline aside (formerly docs/architecture.md:32) and the Ractor note on Spinel's thread list (formerly line 23) are stated nowhere else. Fix: record in docs/architecture.md, or in a follow-up change's notes, that the baseline aside was dropped content, and restore the Ractor fact if it is still needed.
- Also: CLAUDE.md, .claude/agents/planner.md, tools/docs_lint.sh, openspec/changes/archive/2026-11-15-design-principles/proposal.md, docs/architecture.md
- Category: pipeline
- Added: 2026-11-15

### plan_apply's comment says no common record though it writes docs/goals.md
- Location: tools/run_state.sh:1317
- Why: two lanes applying goals.md conflict at merge-main. Folded into lane-records.
- Fix: correct the comment and apply goals.md only in the sprint records change, or name it as the one shared write.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### The goals rubric still splits only a brief of more than about four fixes
- Location: docs/goals.md:24
- Why: the planner decides by the goals rubric (planner.md step 2), which still splits only a brief of more than about four separate fixes, contradicting planner.md step 3's split at three or more independently testable parts or map areas, so the planner can read two thresholds.
- Fix: rewrite goals.md line 24 to the three-part or three-area threshold when the planner is next asked for goals, or point it at planner.md step 3.
- Category: pipeline
- Added: 2026-11-17

### The tier trial's keep rule does not say how its figures compare

- Location: `docs/goals.md:38`
- Why: the rule compares 6 deliveries with 10 rows without saying whether each figure is a per-row rate or a mean, which history (both lane files in merge order, or one lane), or how `total_tokens` of changes of mixed sizes compare, so the planner's verdict can be read either way.
- Fix: state per-row rates and means over both lane histories in merge order, `total_tokens` taken against each row's estimate budget.
- Category: pipeline
- Added: 2026-11-19

### A merge-main carry keeps a review pass across a docs/goals.md commit (review-trust-lows quality, notes 1, 4)
- Location: `tools/run_state.sh:3673` (moved_change filters only RECORDS_RE), `tools/run_state.sh:1561` and `:1563` (settled_round's inline copy of the filter); queued as backlog Pool 11 `moved-change-instructions`.
- Why: #266 settled no pass across a docs/goals.md commit in reviewed_edits, but the merge-main carry still lets a review stand across a branch commit to an instruction record after the pass, the same stale-pass defect by another path; settled_round keeps its own copy of the outside_records filter #266 extracted.
- Fix: count INSTRUCTION_RECORDS_RE paths as changed in moved_change (or refuse the carry when moved_names holds one) and use outside_records in settled_round, keeping the docs/sprints.tsv line; accepted when a tools-test case of a carried pass across a docs/goals.md commit fails before the fix.
- Also: tools/run_state.sh, docs/sprints.tsv
- Category: pipeline
- Added: 2026-11-21

### moved_change carried reviews across a branch-side docs/goals.md edit (review-trust-lows security Low (6))
- Location: tools/run_state.sh:3666 moved_change (reported at :3673, before the branch's moved_change fix)
- Why: dropping every RECORDS_RE path, docs/goals.md included, from REVIEWED, CURRENT, and MOVED let a goals.md edit committed after the security pass and before merge-main go uncompared, so moved recorded the carry and the review was rewritten at the new head, where settled_at trivially passes, reopening the stale-pass path settled_at, settled_round, and reviewed_edits close.
- Fix: moved_change now filters through outside_records (keeping INSTRUCTION_RECORDS_RE paths), with the tools-test case "run_state: moved reruns the reviews when an instruction record changed after the pass"; confirm at review that the case covers an edit after the review, then merge-main, then moved, expecting the refusal, and close this entry if it does.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-21

### The medium budget sits below one delivery's floor
- Location: `docs/goals.md:23` (sizes), `docs/metrics-feature.tsv` total_tokens.
- Why: the refactor-only status-winbar-tabs (#262) took 1,226,138 total tokens against medium's 1.2M, and every medium-estimated feature row of the last ten went over: message-styling 1,470,193, finder-match-strict 1,971,222, finder-grep-preview 2,075,638, background-detect 1,756,083, so the medium estimate does not separate one change from another.
- Fix: the sprint planner's calibration weighs a medium budget from these rows (or a fixed per-delivery floor plus a per-part figure); accepted when the next six medium rows split about evenly over and under the budget.
- Also: docs/metrics-feature.tsv
- Category: pipeline
- Added: 2026-11-21

### Medium-estimate feature runs overrun their 1.2M budget (cmdline-editing evidence, near-same, to be merged into that entry)

- Location: `docs/goals.md` The rubric (sizes), `sh tools/run_state.sh budget`, and the mid-run overrun note at each check pass; cmdline-editing notes 5, 6, 1, 2.
- Why: 12 of 12 medium rows in the last 10 of each lane exceed 1,200,000 total tokens (feature 1,226,138 to 2,192,549; backlog 1,362,861 to 2,119,140); cmdline-editing 1,418,893 total in 131 minutes wrote 2 overrun notes (299,373 and 406,940 output against 200,000) and continued unchanged both times.
- Fix: as that entry; accepted when a majority of the next 10 medium rows end under their size's budget, or no mid-run overrun note is written that no phase acts on.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### Medium-estimate feature runs overrun their 1.2M budget

- Location: `docs/goals.md` The rubric (sizes) and `sh tools/run_state.sh budget`; showtabline note 3, backlog-per-file note 5.
- Why: showtabline 1,365,817 total tokens, 247,686 output against the medium output budget 200,000; backlog-records-rule 1,433,807 in 75 minutes; feature mediums in the last 10 rows 1,226,138 to 2,192,549, 5 of 5 over 1.2M.
- Fix: recalibrate the medium budget from the lane histories or estimate such features large; accepted when at most 1 of the next 5 medium runs overruns.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-21

### The contributor overran the medium budget at agent/high (review-in-openspec overrun note 12)
- Location: docs/goals.md Calibration, the contributor-tier-high end; .claude/workflows/deliver-change.js CALIBRATION.
- Why: estimated medium, budget 1,200,000 total tokens, actual 1,372,173 total tokens in 76.0 minutes, 260,867 output tokens.
- Fix: count it in the contributor-tier-high comparison; accepted when the next calibration decision cites this row with its figures.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-22

### sprint-27-records ran 44.3 minutes against the small budget of 25 (sprint-close-lows overrun note 4)
- Location: docs/goals.md budgets, the records change; beside the backlog queue's `budget-recalibrate` (sprint-26-records budget 0 against 2,612,300).
- Why: estimated small, budget 500,000 total tokens and 25 minutes, actual 0 total tokens in 44.3 minutes, 32,707 output tokens, 8,122,940 total tokens of sprint-planning's reviews set apart.
- Fix: fold into `budget-recalibrate`; accepted when a records change's budget counts its reviews' tokens and minutes or names them apart, and the next records row is judged against it.
- Category: pipeline
- Added: 2026-11-22
