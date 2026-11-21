# Backlog: docs/sprints.tsv

## sprint-16 row names the wrong six changes

- Location: docs/sprints.tsv:19, tools/run_state.sh:2295 (sprint_row)
- Why: the sprint-16 row names moved-review-carry (merged after the plan, the next sprint's security-first item) in place of plugin-lazy-activate, whose history row is only on bugfix/tab-close-d, so its names, wall time, tokens, and first-pass figures describe the wrong six changes; sprint_row reads only history rows while sprint_names counts the merged change without one.
- Fix: make sprint_row (or groom) refuse or wait when a merged sprint change has no history row, then rewrite the sprint-16 row in a records change once plugin-lazy-activate's row is on main.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-18
