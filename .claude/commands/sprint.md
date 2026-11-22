---
description: Close the sprint once its six changes merged (five before sprint-17): the sprint-end review, the backlog grooming, and the next sprint's queue; ends at once when not due
---

Run sprint planning now. Start it after every merge, before the next `/deliver`; it decides for itself whether the sprint is due.

1. Run the Workflow tool with `scriptPath` `.claude/workflows/sprint-planning.js` and no `args`. Its first start runs `sh tools/run_state.sh review-due`; before the sprint's last counted merge, or while the sprint's plan waits in `build/plan/` for the next delivery's package step, it ends at once with that line.
2. Show its report as it is: the security findings first (disputed ones named), then quality, the sweep, the plan, and the next queue. If the security review did not run, say so; it is never skipped silently.
3. Fix nothing yourself and edit nothing tracked. No records run follows: the next delivery's package step runs `sh tools/run_state.sh groom <change>`, which folds the findings files into the backlog and applies the grooming, the lane queues, and the sprint's row in `docs/sprints.tsv` in that delivery's own pull request. When the report says the next queue is held, deliver the security fix first; the first delivery planned after it merged applies the plan. A blocking or disputed High or Medium security finding goes to the user first.
