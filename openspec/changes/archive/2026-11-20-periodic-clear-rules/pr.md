fix(pipeline): clear a periodic security review only by record time and scope

## Summary

A failing periodic security review now stays named by `plan-needed` until a change whose planner read the review runs after the review was recorded merges, or a later whole-tree periodic security review passes, and the sprint report names a partial or unrecorded sweep. Before, a merge planned at a commit after the reviewed one but before the review was recorded, a delivery resumed past its plan, or a sprint's diff-only pass could clear the review without any planner being handed it, so the security-first stop never applied. The run state now records when the periodic security review was recorded and when `plan-needed` last read the review runs before a change's planner, and the clearing rules compare those times instead of commit ancestry alone.

---

## Changes

- Change `merged_since` in `tools/run_state.sh` to clear a failing periodic security review only for a merged change whose planner ran and whose `at.plan-needed` is strictly later than the review's record time, and to clear no review that has no record time
- Change `passed_since` to let only a later passing whole-tree review (`review-DATE`, `sprint-N-sweep`) supersede a failing one, recorded after it and at a descending commit, never a sprint's diff review (`sprint-N`)
- Add the record times: `review` writes `at.review.periodic-security`, `plan-needed` writes `at.plan-needed` while the change's plan is still ahead, and `set` refuses an `at.*` key
- Add `sweepLine` to `.claude/workflows/sprint-planning.js`, so the report names a partial sweep's security and quality areas not reviewed and says when its results were not recorded
- Add tools-test cases for each clearing rule, a resume past the plan, the record times, a sweep pass superseding while a diff pass does not, the sweep line, and a passing periodic security review leaving `plan-needed` taking the head as written
- Document the rules in the run state header, the comments of `merged_since`, `passed_since`, `plan_needed`, and `planReview`, the README pipeline step 1, and the code map entry of `tools/run_state.sh`
- Add the archived OpenSpec change, the findings file with one advisory left open, the backlog lane queue the planner wrote, and the backlog lane's metrics history row

---

## Testing

- Run the security review of the committed diff, pass with no finding (high 0, medium 0, low 0)
- Run the quality review, pass with no blocking finding and one advisory, recorded in the findings file
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark comparison against main, pass with no regression
- Run make spec-validate, 54 passed and 0 failed
- Run make gates and make docs-lint, all pass

---

## Notes

Three headings of the queue item are left to other queue items, which the planner placed: the open-pr action pins go to pr-trust-lows-c, and the lane worktree trust and the change-name checks of lane-close and merge-main go to lane-name-guards. A review recorded before this change has no record time, so no merge clears it and only a later whole-tree pass does. The quality advisory left open is that `plan-needed` names only the first failing review while `merged_since` clears every review recorded before the planner's time; it is recorded in the findings file. `tools/rules.sh` is not edited.
