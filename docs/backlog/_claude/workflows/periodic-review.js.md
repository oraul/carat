# Backlog: .claude/workflows/periodic-review.js

## The periodic quality slices count a repeated finding twice

- Where: the slice results in `.claude/workflows/periodic-review.js` (lines 94, 115, and 116 at 594dd35) merge blocking and advisory findings with `flatMap`. Quality advisory in `partial-results`.
- Why it matters: a continued start that repeats a finding of its first start counts it twice in the recorded results the planner reads.
- Fix outline: drop duplicates as `combineReviews` in `.claude/workflows/deliver-change.js` does.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-07

## Periodic review slices cut the map areas by count

- Where: `areaSlices` in `.claude/workflows/periodic-review.js:67`. Periodic quality at 9a92265.
- Why it matters: slice 1 puts area 1 (about 8,850 lines and a 425 KB backlog) with five more areas under one 53-call cap, so the guard, the tools test, and most of the gates go unread.
- Fix outline: weight slices by size or give area 1 its own. Queue item `review-scope`.
- Category: pipeline
- Added: 2026-11-10

## The periodic slices put area 1 under one cap

- Where: `.claude/workflows/periodic-review.js:67` (`areaSlices` splits by area count; area 1 holds about 6,700 lines). Periodic quality at bd86828.
- Why it matters: the slice holding area 1 caps and the review ends partial by design.
- Fix outline: none prescribed; superseded if the council reviews diffs. Queue item `periodic-council`.
- Category: pipeline
- Added: 2026-11-11

### Stale review-due comment in the periodic review (`sprint-planning` quality advisory)

- Location: `.claude/workflows/periodic-review.js:122`.
- Why it matters: the comment says a partial review keeps the next one due, but `review-due` now counts sprints only, so a reader is misled about when the review runs again.
- Fix outline: drop the review-due clause or state the new rule.
- Category: pipeline
- Added: 2026-11-11

### Periodic quality slices split areas by count

- Location: .claude/workflows/periodic-review.js:65 (sprint-4 sweep, quality).
- Why: slice 1 holds area 1, about 10,000 lines, which one start cannot read; the sweep left areas 1, 13, 14, 15 unreviewed (covered 14/18).
- Fix: weight slices by line count, or split area 1 in the map.
- Category: pipeline
- Added: 2026-11-14

### Periodic sweep tokens still count in the records budget
- Location: .claude/workflows/periodic-review.js:142
- Why: the sweep runs inside sprint-planning but its record start is labelled record, which add_tokens keys record, not sprint, so its tokens still count in the records change's budget; raised twice by the quality review, merged here.
- Fix: label it periodic: record or match the sweep's record in add_tokens.
- Category: pipeline
- Added: 2026-11-18

### Every sweep leaves area 1 partial (sprint-24 sweep quality)

- Location: `.claude/workflows/periodic-review.js:65`
- Why: QUALITY_SLICES splits 18 areas by count, but area 1 (about 14,000 lines of shell) exceeds one 53-call start, so both starts cap (`review.periodic-quality` partial 17/18).
- Fix: split area 1 in the map or slice by size.
- Category: pipeline
- Added: 2026-11-21

### areaSlices gives map area 1 (about 18,000 lines: run_state.sh at .claude/workflows/periodic-review.js:70 (sprint-26 sweep quality, note 49)

- Location: .claude/workflows/periodic-review.js:70
- Why: areaSlices gives map area 1 (about 18,000 lines: run_state.sh 4,269, tools_test.sh 6,145, deliver-change.js 1,961, agent_guard.sh 1,161) the same share as every other area, more than one 53-call start can read, so the sweep of area 1 stays partial after its continuation
- Fix: split area 1 in docs/codebase-map.md (CI and gates, the run state, the guard and the workflows) or weight the slices by size
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-22

### periodic-review inlines the commit regex and slices areas by count at .claude/workflows/periodic-review.js:67 (sprint-28 sweep quality, notes 56, 57)

- Location: .claude/workflows/periodic-review.js:58, :67, :74; .claude/workflows/deliver-change.js:449, :641, :1080
- Why: isCommit and COMMIT are restated inline; area 1 alone is about 18,000 lines, so its slice and continuation cap, as the sprint-28 sweep did (covered 17/18).
- Fix: use the helpers; give area 1 its own start or weight slices by line count.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-22

### periodic-review.js's record start still runs unguarded on the session's model

- Location: `.claude/workflows/periodic-review.js`, the record start (`RECORD_CAP`), started with no `agentType`.
- Why: it runs one workflow-written `tools/run_state.sh review` line like the delivery's record start, which `cheap-tier` moved to the guarded runner on the cheapest tier; this one still costs the session's model and has no hook.
- Fix: start it with `agentType: 'runner'` at low effort and add a tools-test case, once its keep rule over the next 5 rows holds for the delivery and sprint starts.
none

none
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-22
