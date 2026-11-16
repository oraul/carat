# Design

## Context

See proposal.md, Why. The periodic reviews record `review.periodic-security` as `RESULT COMMIT SUMMARY` (`tools/run_state.sh review`), RESULT one of pass, blocked, partial, not-run; the workflows' `result` helper writes `partial` before `blocked` when an area went unreviewed, so a partial result may still carry `blocking=N` in its summary. `pending_list` lists only run states with a merged commit, which no review run has. `sprint_state` builds `sprint_names` from the history rows after the last sprint's last change, then the pending changes; `sprint_row` walks the same history rows.

## Goals / Non-Goals

Goals: the planner runs while a failing periodic security review stands; a sprint closes after a bounded number of merges; a sprint's row never reaches past its fifth counted change. Non-goals: deciding whether a finding is fixed (the planner does), and history row order.

## Decisions

- Failing record: `blocked`, or a summary with `blocking=` followed by a non-zero count. Alternative, `blocked` only: misses the partial-with-blocking case the workflows write.
- Cleared by a later merge (`merged_since COMMIT`): the newest history row's merged commit, or a pending change's, descends from COMMIT and differs from it. Alternative, cleared only by a later passing periodic review: every delivery until the next sprint review would run the planner even after the fix merged, a cost of about 15% of a run's output tokens each time. A merge after the review passed a planner that plan-needed sent the finding to, which stops the run unless the brief fixes it. That holds only when the planner reads the review: plan-needed names a failing review before any other reason, and the workflow puts the review run it names into the planner prompt (`planReview`), whose `show` the planner reads, since its `pending` list holds merged run states only. A commit git does not know leaves the record standing, so a shallow or stale clone errs toward planning.
- Cap: `SPRINT_EXCEPTIONS=1`, the first marked change in `sprint_names` order exempt; the loop stops once the cap is reached, so later queue reads are skipped. Alternative, a cap of two: no sprint has needed two, and every exception delays the sprint review by a merge.
- Row end: `sprint_row` stops at the first row after the fifth counted one, exception or not. An exception merged before the fifth counted change but given a later history row (rows follow the run states' order) moves to the next sprint's list; its diff was already in this sprint's combined diff, so no diff goes unreviewed, only its exemption is spent in the next sprint.

## Risks / Trade-offs

- A run resumed past its plan phase (`phase.plan` recorded) does not re-plan when a review blocks after it started; the next delivery plans.
- An exception counted in the next sprint because of row order uses that sprint's one exemption; a second marked change there counts, which ends that sprint no later than six merges.
