---
description: Close the sprint once its six changes merged (five before sprint-17): the sprint-end review, the backlog grooming, and the next sprint's queue; ends at once when not due
---

Run sprint planning now. Start it after every merge, before the next `/deliver`; it decides for itself whether the sprint is due.

1. Run the Workflow tool with `scriptPath` `.claude/workflows/sprint-planning.js` and no `args`. Its first start runs `sh tools/run_state.sh review-due`; before the sprint's last counted merge, or while the sprint's plan waits in `build/plan/` for its records change, it ends at once with that line.
2. When its report names a records change, record the workflow's cost on it as `/deliver` step 3 does: `sh tools/run_state.sh usage sprint-N-records <tokens> <minutes>`, then `sh tools/run_state.sh tokens sprint-N-records <dir>` with this Workflow run's transcripts directory. `tokens` keys sprint-planning's own starts `sprint`, and `budget` sets them apart, so the records change's budget counts only its own work.
3. Show its report as it is: the security findings first (disputed ones named), then quality, the sweep, the plan, and the records change. If the security review did not run, say so; it is never skipped silently.
4. Fix nothing yourself and edit nothing tracked. The workflow's last phase delivers the sprint's records change, `sprint-N-records`, whose implement step alone runs `sh tools/run_state.sh groom`, which folds the findings files into the backlog and applies the grooming, the lane queues, and the sprint's row in `docs/sprints.tsv`; no delivery's package step runs it. When the report says the records change did not finish, resume it with `/deliver sprint-N-records`; when it says the records change is held, resume it only after the security fix merged. A blocking or disputed High or Medium security finding goes to the user first.
