## sprint-16 row names the wrong six changes

- Location: docs/sprints.tsv:19, tools/run_state.sh:2295 (sprint_row)
- Why: the sprint-16 row names moved-review-carry (merged after the plan, the next sprint's security-first item) in place of plugin-lazy-activate, whose history row is only on bugfix/tab-close-d, so its names, wall time, tokens, and first-pass figures describe the wrong six changes; sprint_row reads only history rows while sprint_names counts the merged change without one.
- Fix: make sprint_row (or groom) refuse or wait when a merged sprint change has no history row, then rewrite the sprint-16 row in a records change once plugin-lazy-activate's row is on main.

## Fold adds a level-one heading per findings file

- Location: docs/backlog.md:7740, tools/run_state.sh:2143 (folded_backlog)
- Why: the fold adds a third level-one heading ('# Findings of sprint-15-records'), the very defect the folded entry under it records, nesting every later entry under it.
- Fix: drop the title line here and let folded_backlog skip a findings file's leading '# ' line.

## Folded headings lack a blank line before them

- Location: docs/backlog.md:7643, 7647, 7651, tools/run_state.sh (folded_backlog)
- Why: folded headings follow a text line with no blank line before them (the known fold defect, again).
- Fix: insert the blank lines and have folded_backlog separate every folded heading by one blank line.

## Committed queue still lists a merged security-first item

- Location: docs/queue-backlog.md:22
- Why: the committed queue still lists moved-review-carry under Security first though it merged as #199, relying on the package step's plan-apply to drop it.
- Fix: confirm plan-apply removes the section before the merge, or have groom drop queue items already merged.

## Records proposal names a file the diff does not touch

- Location: openspec/changes/archive/2026-11-18-sprint-16-records/proposal.md:25, tasks.md:7
- Why: Impact (and task 1.2) names docs/metrics-feature.tsv, which the diff does not touch.
- Fix: drop it from Impact and say in task 1.2 that only docs/metrics-backlog.tsv gains a row.

## New Pool drops items with no Decisions line

- Location: docs/queue-backlog.md:30, docs/backlog.md:137, 1017, 1168
- Why: the new Pool drops plugin-host-tidy batch 2 part b (PluginUi, bars comments, in_window, move_float), plugin-host-move, package-advisory-edit, lint-own-queue-paths, plan-skip-placed, scout-pack-reuse, and merge-cap-ci-wait with no Decisions line, their headings left in docs/backlog.md.
- Fix: the next planner run states each drop or puts the items back in the Pool.
