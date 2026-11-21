### A plan decision amending the brief does not reach the contributor (contributor-tier-high retro note 7)
- Location: .claude/workflows/deliver-change.js, the contributor's brief; docs/queue-backlog.md:11 at contributor-tier-high
- Why: its planner amended the brief (backtick the exception line's names, as queue_class needs), the contributor got only the brief, wrote bare names, and quality blocked at 43228fb; the fix round cost 157,564 output tokens (31,138 to 188,702); quality first pass 137/229, the weakest gate.
- Fix: hand the plan's amendments to the contributor with the brief; accepted when a run whose plan amends the brief has no quality-blocking finding on that amendment.

### An advisory confined to the change's own findings file costs a full round (contributor-tier-high retro note 8)
- Location: .claude/workflows/deliver-change.js, the fix round; near the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: contributor-tier-high's second round was a two-line wording fix in its findings file, output 188,702 to 218,283 (29,581), over the medium 200,000 output budget, with a check rerun at f95b02af0634, not the head; review-trust-lows-b rework 3, sprint-24-records rework 2, on 0 blocking.
- Fix: close such an advisory without a round; accepted when rework is unchanged and no check reruns. Merge into `closing-loop-fold` when groomed.

### The check phase spends a large output share on runs whose stages pass first time (contributor-tier-high retro note 9)
- Location: .claude/workflows/deliver-change.js, the check phase; tools/run_state.sh check
- Why: contributor-tier-high check 56,453 of 260,867 output (21.6 percent) for 12 calls with first.check 1; groom-evidence-only 119,742 of 338,328 (35.4 percent); check first pass 217/229.
- Fix: keep a first-pass check's output small; accepted when a run with first.check 1 spends at most 10 percent of its output in check.

### The merge phase cost grows with the merger's waiting, not with CI (border-vocabulary retro note 2)
- Location: .claude/workflows/deliver-change.js, the merger; evidence for the queued `merge-wait-bound` (docs/queue-backlog.md Pool)
- Why: border-vocabulary merge 142,172 of 518,649 output (27.4 percent), 18 calls, ci_wait_calls 10 at 11.4 CI minutes; the last 10 feature rows merge 18,467 to 85,414 output, ci_wait_calls 6 at 10.0 to 12.0 CI minutes.
- Fix: bound the wait; accepted when over the next 5 runs with CI at most 12 minutes the merge phase stays at or under 40,000 output tokens and ci_wait_calls at or under 6.

### A round for one test-only advisory reran every phase with unchanged results (border-vocabulary retro note 3)
- Location: .claude/workflows/deliver-change.js; evidence for the queued `closing-loop-fold` (docs/queue-backlog.md Pool)
- Why: output at the check passes 204,095 then 348,268 (144,173, 27.8 percent of 518,649), rework 1 on 0 blocking, security 0 and bench equal on both passes; tabs-only-dot 155,089, groom-evidence-only 105,718, listchars-folds 107,710 on 0-blocking rounds.
- Fix: accepted when over the next 3 runs whose first reviews report 0 blocking, rework is 0 or the round costs under 10 percent of the run's output.

### The package step repeats a self-review of a diff the reviewers passed unchanged (border-vocabulary retro note 4)
- Location: .claude/agents/contributor.md, the package step; evidence for the queued `contributor-rule-ten` (docs/queue-backlog.md Pool)
- Why: the package self-review ran at 0e51012116a9 after security 0 and quality 0 at that commit, changing no decision; package 10,649 output, 20 calls; the relayed idea of the contributor reviewing itself goes against CLAUDE.md (reviewers never edit), so the duplicate goes instead.
- Fix: accepted when the package step does no self-review of a diff reviewed-edits reports unchanged since the reviews, and package calls fall below 20.
