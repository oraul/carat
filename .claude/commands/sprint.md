---
description: Close the sprint once its five changes merged: the sprint-end review, the backlog grooming, and the next sprint's queue; ends at once when not due
---

Run sprint planning now. Start it after every merge, before the next `/deliver`; it decides for itself whether the sprint is due.

1. Run the Workflow tool with `scriptPath` `.claude/workflows/sprint-planning.js` and no `args`. Its first start runs `sh tools/run_state.sh review-due`; before the sprint's fifth merge, or while the sprint's plan waits in `build/plan/` for the next package step, it ends at once with that line.
2. Show its report as it is: the security findings first (disputed ones named), then quality, the sweep, and the plan. If the security review did not run, say so; it is never skipped silently.
3. Fix nothing yourself and edit nothing tracked. The next `/deliver`, the head item of `build/plan/queue.md`, carries the plan: its package step runs `sh tools/run_state.sh groom`, which applies the grooming, the queue, and the sprint's row in `docs/sprints.tsv`. A blocking or disputed High or Medium security finding goes to the user first.
