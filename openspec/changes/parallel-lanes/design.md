# Design

## Context

`tools/run_state.sh` writes every record a package step commits: `history` (append_history) appends a row for each pending merged change to the lane file `lane_of` picks, and `groom` applies the sprint plan waiting in `build/plan/` (both lane queues, the findings fold into `docs/backlog.md`, the `docs/sprints.tsv` row). The contributor's package step copies `build/plan/queue-*.md` and `goals.md` itself, then runs `history` and `groom`. Every planner writes the same `build/plan/` files.

## Goals / Non-Goals

Goals: two lanes' planners never share a file; one lane's package step writes only its own lane's queue and metrics; the sprint's fold and row are written once, by sprint-planning. Non-goals: the worktrees and running two deliveries at once (parallel-lanes-b).

## Decisions

- Per-change plan directory `build/plan/<change>/`: a change name is unique (`init` refuses a merged one) and its lane derived, so no two planners can collide, whatever lane; per-lane would collide between two runs of one lane after a stop. The sprint planner keeps the root, so `review-due`, `plan-needed`, and `groom` read the sprint plan where they did.
- `plan-apply CHANGE` in the script rather than a `cp` in the prompt: the copy becomes one tested behavior that cannot touch the other lane's queue. It takes the lane from `lane_of`, extended for an unmerged change (the lane queue at HEAD, then at BASE, naming its item, else its recorded branch's type), since by the package step the planner may have removed the item.
- `history CHANGE` filters the pending changes by lane: the other lane's rows wait for its next package step. A records change appends every lane, since `groom` needs the sprint's five rows whatever their lanes.
- The records change: sprint-planning starts `deliver-change.js` with `{ change: 'sprint-N-records', branch: 'chore/sprint-N-records', brief }`, as it already starts `periodic-review.js`. Its contributor runs `history` and `groom sprint-N-records` as its implement step, so the records pass the checker, the reviews, and the merge gates; its package step applies no plan and runs neither command. `groom` refuses any other change name, so a delivery's package step can no longer write the fold or the row. `plan-needed` says not needed for the records change (after the security check), so no planner runs for it.

## Risks / Trade-offs

- Each sprint costs one more small delivery (records-only, docs stages only). Accepted: it is what writes the records once.
- Until a lane's next package step, the other lane's pending rows are absent from its history file; `status` and `bench` read the files as they are, as they did between a merge and the next package step.
- A stopped records change leaves the plan waiting (`review-due` not due); `/deliver sprint-N-records` resumes it, which the sprint-planning report says.
