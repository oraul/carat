chore(pipeline): keep each lane's records to its own package step

## Summary

Keeps each delivery lane's records to its own package step: a delivery's planner writes its own plan directory, the package step applies only its lane's queue and appends only its lane's metrics rows, and the sprint's backlog fold and sprints row are written once, by a records change sprint-planning delivers. A feature delivery and a backlog delivery could not run at once, since both package steps wrote the same queues, metrics, backlog fold, and sprint row. This is the records separation of parallel-lanes; the worktrees, merging a moved main, and the one-delivery-per-lane rule follow as parallel-lanes-b.

---

## Changes

- Add `sh tools/run_state.sh plan-apply CHANGE`, which applies the planner's `build/plan/CHANGE/` for the change's lane only: its lane queue, the goals, and the backlog notes appended to the change's findings file, leaving and naming the other lane's queue.
- Change `history CHANGE` to append only the pending rows of the change's lane, leaving the other lane's rows to that lane's next package step; a sprint's records change and a call with no change still append every lane's rows.
- Change `groom` to apply a waiting sprint plan only for its records change `sprint-N-records`, refusing any other change, and have `plan-needed` treat that change as not needed unless a failing periodic security review comes first.
- Change `lane_of` to read a not yet merged change's lane from the lane queue at HEAD or BASE naming it, else from its branch type.
- Add a Records phase to the sprint-planning workflow that delivers `sprint-N-records` through the delivery workflow and reports whether it merged from its run state, with the resume hint when it did not.
- Change the delivery workflow to point the planner at `build/plan/CHANGE/` and to run `plan-apply` and `history` in the package step, never `groom`.
- Change the agent guard, the planner and contributor instructions, and the sprint command to name the plan directory and the new steps.
- Add tools-test cases over fixture repositories for the lane-only plan apply and history, the goals copy, the lane from BASE's queue, the groom refusal, and the records change's finished check.
- Document the plan directory, `plan-apply`, the lane-only history, and the records change in the README and area 1 of the codebase map.

---

## Testing

- Security review of the committed diff: pass, high 0, medium 0, nothing blocking; a Low process-gate note on the records change and a blocking sprint finding is recorded in the change's findings file
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run make spec-validate after archiving, 53 passed, 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

- CLAUDE.md is unchanged: its Sprints, Backlog, and Run state bullets still describe groom in the next package step and the shared plan files, left for the user to approve with parallel-lanes-b, which edits the same Agents section for the two-lanes rule.
- This change does not yet let two deliveries run at once: the worktrees under a hidden tmp directory, merging a moved main into a running delivery, and the one-delivery-per-lane rule are parallel-lanes-b.
- tools/rules.sh is unchanged.
