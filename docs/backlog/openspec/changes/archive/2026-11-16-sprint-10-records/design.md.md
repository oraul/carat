# Backlog: openspec/changes/archive/2026-11-16-sprint-10-records/design.md

### Records change steps outside groom to fix the queues and docs-lint (quality advisory)

- Location: openspec/changes/archive/2026-11-16-sprint-10-records/design.md:13 (written as openspec/changes/sprint-10-records/design.md:13)
- Why: one clear way: the records change hand-copied the delivery plan's feature queue over groom's copy (the sprint plan still named the merged git-signs-trust) and hand-edited a folded entry and an ignored plan file so docs-lint passes, steps outside groom.
- Fix: make groom prefer build/plan/CHANGE/queue-*.md when present (or plan-apply copy both lanes for a records change) and refuse or de-backtick a nonexistent path while folding, with tools-test cases.
- Category: pipeline
- Added: 2026-11-17
