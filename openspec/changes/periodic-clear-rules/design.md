# Design

## Context

A periodic security review (`/review`'s `review-DATE`, the sprint sweep `sprint-N-sweep`, and the sprint's diff review `sprint-N`) records `review.periodic-security` as `RESULT COMMIT SUMMARY` in its own run state. `plan-needed` names the first failing one unless `merged_since` (a change planned after it merged) or `passed_since` (a later passing review) clears it. Both judged "after" by commit ancestry, and `passed_since` took any review run's pass.

## Goals / Non-Goals

Goals: a failing review is cleared only by a delivery whose planner read the run states after the review was recorded, or by a later passing review whose scope covers it; the sprint report states what the sweep left. Non-goals: the planner's behavior, the review record format, the other queue headings.

## Decisions

- Record times live in their own keys, `at.review.KIND` and `at.plan-needed`, so the `RESULT COMMIT SUMMARY` readers (`plan_needed`, `review_due`, `trusted_state`, the workflows) are untouched. `trusted_state` passes any key outside `phase.*`, `review.*`, and `merged`, so the times survive a resume. `set` refuses `at.*`, as it refuses `review.*` and `phase.*`.
- The planner's time is written by `plan-needed`, which the workflow runs at every start right before the Plan phase and whose line it hands the planner, and only while no `phase.plan`, `phase.implement`, or `merged` record exists: the workflow runs the planner under exactly that condition, so the time is the last read before the planner, and a resume past the plan keeps it. The `phase.plan` record cannot carry it: the workflow queues it and flushes it after the implement step.
- Times are `utc_now` strings (`YYYY-MM-DDTHH:MM:SSZ`), validated, compared as strings by `later_than`, strictly.
- A review without a record time (recorded before this change) keeps the ancestry rule in both functions, so the run states already on disk neither clear nor stick differently; a review with one is never cleared by a change or a pass that lacks one.
- The scope is read from the run name, which only the workflow that writes it chooses: `sprint-N` exactly is a diff review; every other review run is whole-tree. `passed_since` takes only whole-tree passes.
- `sweepLine(on, sweep)` is a named function, so `tools/tools_test.sh` runs it through `js` as it runs `securityLine`'s siblings.

## Risks / Trade-offs

- A failing review recorded before this change but cleared by an old merge stays cleared (ancestry); a new one needs a delivery planned after it. The next delivery's planner clears a standing one, at the cost of one planner start.
- Two record times in the same second count as not later, which may run the planner once more; fail closed.
