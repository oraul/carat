# Design

## Context

See proposal.md, Why. A periodic review records `review.periodic-security` as `RESULT COMMIT12 SUMMARY` on its own run state. The delivery workflow records `phase.plan` (`tools/run_state.sh phase CHANGE plan COMMIT`) at its head when the planner returns, and also when it skips the planner (`planSkipped`), in which case its metric line stores `metric.planned=0`. The newest history row of `docs/metrics.tsv` names its change in column 1 and its merged commit in column 3; a pending change is a run state with a merged commit on main and no row (`pending_list`).

## Goals / Non-Goals

Goals: a failing periodic security review is cleared only by the merge of a delivery whose planner could have read it. Non-goals: deciding whether the finding is fixed (the planner does), and recording times.

## Decisions

- Cleared by (`merged_since COMMIT`): a merged change, the newest history row's or a pending one's, whose merged commit descends from COMMIT and differs from it (as before), whose `phase.plan` commit also descends from COMMIT and differs from it, and whose `metric.planned` is not `0`. Main only moves forward, so a planner that ran after the review recorded either COMMIT itself or a descendant; a planner that ran before it recorded COMMIT or an ancestor. Alternative, accept `phase.plan` equal to COMMIT: a planner run at the same main commit just before the review would clear it. Requiring strict descent fails closed at the cost of one more planner run: the next delivery's plan-needed still says needed, its planner runs at a later main commit, and its merge clears the review.
- Skipped planner: `phase.plan` is written when the plan phase is skipped too, so `metric.planned=0` excludes it; a skip at a later commit means plan-needed ran before the review was recorded, and no planner read it. Alternative, `phase.plan` alone: a race between a long review and a delivery start would clear it unread.
- Reading the newest row's run state: the row's column 1 passes `valid '[a-z0-9][a-z0-9-]*'` before it names a run state file, so a hand-edited row cannot reach another path. A row whose run state is gone clears nothing (fail closed).
- Cost: two `read_key` awk runs and one or two `git rev-parse`/`merge-base` calls per candidate, only while a failing review stands; tools-test adds two `plan-needed` runs and two record writes.

## Risks / Trade-offs

- A failing review stands longer: after a review, the first delivery planned before it no longer clears it, so the next delivery runs the planner, about 15% of a run's output tokens, which is the point of the fix.
- A run state removed by hand (a fresh clone has no `build/pipeline/`) leaves the review standing until a merge whose run state is present, or a passing periodic review.
