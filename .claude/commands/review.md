---
description: Review the whole codebase at main now, the security review first, and record the findings for the planner
---

Run the periodic review now. The delivery workflow already runs it every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the agent guard and the gates; this runs it on demand.

1. `git fetch -q origin`, then name the run state `review-<UTC date>` from `date -u +%Y%m%d` (add `-2`, `-3` when one of that name exists under `build/pipeline/`), and create it at main: `sh tools/run_state.sh init <name> main` and `sh tools/run_state.sh set <name> merged "$(git rev-parse --short=12 origin/main)"`.
2. Run the Workflow tool with `scriptPath` `.claude/workflows/periodic-review.js` and `args` `{ "change": "<name>" }`. The security reviewer and the quality reviewer review the whole tree at `origin/main` in their periodic mode and record every finding in that run state, and the workflow records their results.
3. Show its result as it is: the security findings by severity first, then quality. If the security review did not run, say so; it is never skipped silently.
4. Fix nothing yourself. The next `/deliver` carries the record: its planner puts a blocking security finding at the front of the queue and the others in the queue or appended to the backlog, and its package step adds the row to `docs/metrics.tsv`, which restarts the count of five.
