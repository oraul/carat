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

### Feature scouts cost about a quarter of a run's tool calls (cmdline-editing evidence, near-same as the `scout-prune` pool item of docs/queue-backlog.md, to be merged into it)

- Location: the scout and areas phases of `.claude/workflows/deliver-change.js`; cmdline-editing note 4.
- Why: scout 51 of 219 calls (23.3 percent) and 72,557 of 481,005 output (15.1 percent) plus areas 5 calls, 5,750 output, for 3 packs, none reused; feature scouts 28 to 45 calls in the last 5; implement still 73 to 92 calls against 46 in the no-scout runs contributor-tier-high and backlog-records-rule.
- Fix: as `scout-prune`; accepted when across the next 10 feature runs scout plus areas stays under 10 percent of tool calls (or is merged away) while implement calls do not rise above the no-scout runs' level.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-21

### Backlog items check-at-head and self-check-drop
- Location: docs/queue-backlog.md Pool 11 (check-at-head, self-check-drop), folded by the plan of contributor-self-check
- Why: this change settles check-at-head as far as its brief names it: the checker's check backs the head the contributor's own passing check recorded (backedCommit), so the stages passed there are skipped; self-check-drop's text could not be read during the delivery (no agent reads the backlog), so it is not named as settled and is kept here to come back.
- Fix: the sprint planner compares self-check-drop's entry with this change's diff and either closes it with this change as evidence or queues what is left.
- Category: pipeline
- Added: 2026-11-21

### backlog.md stale queue reference for review-trust-lows-b

- Location: the folded review-trust-lows-b entries say queued in review-trust-lows-b (docs/queue-backlog.md Sprint 24), but it merged as #268.
- Why it matters: the reference points at a queue Sprint 24 left.
- Fix outline: point them at review-trust-lows-c and pipeline-lows-a (Pool 3, Pool 1) when merged.
- Category: pipeline
- Added: 2026-11-21

### Backlog Pool item 1 marks its Sprint 30 place beside planner-loop, which no queue names

- Location: docs/queue-backlog.md, Pool item 1 ("For Sprint 30, beside `planner-loop`"), written by sprint-28-records on the user's answer of 2026-11-22.
- Why: the user's wording was kept, but neither lane queue holds an item named planner-loop, so the planner of sprint 29 cannot tell what the two moved items sit beside; the records change may not add a queue item of its own.
- Fix: in the sprint-29 planning, queue planner-loop with its sizing or reword Pool item 1 without it.
- Category: pipeline
- Added: 2026-11-22
