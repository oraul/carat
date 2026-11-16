### sprint-10-records proposal miscounts the sprint's changes (quality advisory)

- Location: openspec/changes/archive/2026-11-16-sprint-10-records/proposal.md:5 (written as openspec/changes/sprint-10-records/proposal.md:5)
- Why: it says sprint 10 closed with its five changes merged, while the sprint-10 row of docs/sprints.tsv records size 6 with six changes, so the archived record disagrees with the sprints file.
- Fix: say six changes, backlog-lane-split being the user-approved place beyond the five.

### Lane queues state a stale insert acceptance figure (quality advisory)

- Location: docs/queue-backlog.md:3 and docs/queue-feature.md:3
- Why: both lane queues accept with insert 32.0 held, but every metrics row since #153 records insert=26.0, so a regression of six allocations passes the stated acceptance.
- Fix: have the planner write the current figures (insert 26.0) or point to metrics-compare instead of numbers.

### Records change steps outside groom to fix the queues and docs-lint (quality advisory)

- Location: openspec/changes/archive/2026-11-16-sprint-10-records/design.md:13 (written as openspec/changes/sprint-10-records/design.md:13)
- Why: one clear way: the records change hand-copied the delivery plan's feature queue over groom's copy (the sprint plan still named the merged git-signs-trust) and hand-edited a folded entry and an ignored plan file so docs-lint passes, steps outside groom.
- Fix: make groom prefer build/plan/CHANGE/queue-*.md when present (or plan-apply copy both lanes for a records change) and refuse or de-backtick a nonexistent path while folding, with tools-test cases.

