# Backlog: docs/queue-backlog.md

### Lane queues state a stale insert acceptance figure (quality advisory)

- Location: docs/queue-backlog.md:3 and docs/queue-feature.md:3
- Why: both lane queues accept with insert 32.0 held, but every metrics row since #153 records insert=26.0, so a regression of six allocations passes the stated acceptance.
- Fix: have the planner write the current figures (insert 26.0) or point to metrics-compare instead of numbers.
- Also: docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-17

## Committed queue still lists a merged security-first item

- Location: docs/queue-backlog.md:22
- Why: the committed queue still lists moved-review-carry under Security first though it merged as #199, relying on the package step's plan-apply to drop it.
- Fix: confirm plan-apply removes the section before the merge, or have groom drop queue items already merged.
- Category: pipeline
- Added: 2026-11-18

## New Pool drops items with no Decisions line

- Location: docs/queue-backlog.md:30, docs/backlog.md:137, 1017, 1168
- Why: the new Pool drops plugin-host-tidy batch 2 part b (PluginUi, bars comments, in_window, move_float), plugin-host-move, package-advisory-edit, lint-own-queue-paths, plan-skip-placed, scout-pack-reuse, and merge-cap-ci-wait with no Decisions line, their headings left in docs/backlog.md.
- Fix: the next planner run states each drop or puts the items back in the Pool.
- Category: pipeline
- Added: 2026-11-18

### use-case-surface-c and -d acceptance asks for an analysis-time comparison that decides nothing (use-case-surface-b retro 4)
- Location: `docs/queue-backlog.md` Pool 7 (`use-case-surface-c`, `-d`), its acceptance line.
- Why: use-case-surface-b's implement phase (111,761/68, 41.6 percent of output tokens, 40.5 percent of calls) built a detached worktree of main to compare analysis time; the runner root read 107.0 s on main, 96.8 s on the branch, 128.7 s in the check's metrics stage, a 33 percent spread, while rounds (2 and 2) and allocations (equal in 8 scenarios) decided the benchmark gate.
- Fix: drop the analysis-time comparison from the c and d acceptance, or take both sides from figures the check already records; accepted when part c's contributor builds no second tree of main and its pull request still states rounds and allocations against main.
- Category: pipeline
- Added: 2026-11-20

### Two queue items do not cite the headings folded for them
- Location: docs/queue-backlog.md:17 (groom-findings-refs, Pool 5) and :18 (records-bench-skip, Pool 6)
- Why: the headings 'groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)' and 'A records-only change still runs the benchmark and rebuilds the lane (sprint-22-records retro note 3)' are not in their Backlog lists, so those deliveries are not handed them and leave them open.
- Fix: add each heading to its item's Backlog list in the next plan.
- Category: pipeline
- Added: 2026-11-21
