### Advisory-only rounds chain on their own fixes (status-winbar-tabs-b retro note 16)
- Location: `.claude/workflows/deliver-change.js` (the rework loop), joining the queued backlog Pool 9 `closing-loop-fold`; `test/editor_tab_flows.rb` (the helper the advisories hit).
- Why: every quality pass of status-winbar-tabs-b was blocking=0 (4 passes, 4+1+3+1 advisories) and every security pass found 0, yet two fix rounds and a closing start ran 3 more check and review chains; 6 of 9 advisories (notes 4 to 8, 14) were on the helper the previous advisory fix wrote; output 231,243 at the first check pass and 419,768 at the last, so 188,525 of 544,079 (34.7 percent) went to advisory-only rounds; rework 2 or more in 11 of the last 20 lane rows.
- Fix: a run whose quality passes are all blocking=0 runs at most one fix-and-review chain after its first pass, and an advisory on code an advisory fix added is recorded, not fixed again; accepted when the next such run shows one chain.

### The check reports main's commit, not the head (status-winbar-tabs-b retro note 17)
- Location: the checker start in `.claude/workflows/deliver-change.js`, evidence for the queued backlog Pool 11 `check-at-head`.
- Why: 2 of 6 check starts of status-winbar-tabs-b reported a pass at main's 3af2fc9099f3 instead of heads b5df62c55abd and 535eafb3312b, each needing a rerun; check 100,640 of 544,079 output (18.5 percent) on 18 calls, against 9,588 to 45,667 in the last five lane rows.
- Fix: the check start reports and is judged by the head it ran at; accepted when no check start reports a commit other than the head over the next five runs and the check phase stays under 10 percent of output.

### A head-form refusal restarts a start whose work is committed (status-winbar-tabs-b retro note 18, notes 12, 13)
- Location: `.claude/workflows/deliver-change.js` (the head check and escalation of a closing start).
- Why: a closing start whose commit 535eafb was already HEAD was refused for its head string's form, escalated, and restarted; the restart spent 18,885 output tokens on 13 calls and made 0 commits; 1 head-refused note across all run states.
- Fix: when the committed work is at HEAD and only the reported head's form differs, take the head from git and neither escalate nor restart; accepted when no head-refused note appears over the next five runs.
