# Proposal

## Why

Seven defects let a failing periodic security review clear without anyone reading it, so `plan-needed` stops naming it and the planner's security-first stop never applies (T1 pipeline defect, security Medium (6), estimated large). `merged_since` (`tools/run_state.sh`) judges "planned after the review" by commit ancestry: a delivery planned at a commit after the reviewed one, but before the review was recorded, clears it when it merges, and a resumed delivery planned before the review and merged after it clears it too, its planner never handed the review. `passed_since` lets any passing periodic security review supersede a failing one, a sprint's diff-only review included, though a diff review never re-reads the whole tree a failing whole-tree review covered, contrary to its own comment. The sprint report (`.claude/workflows/sprint-planning.js`) reads the sweep as complete whenever it ran: a partial sweep, or one whose results were not recorded, reports plain counts. And no tools-test case shows that a passing periodic security review alone does not make `plan-needed` need the planner.

## What Changes

- The run state records when a review and a planner looked: `review` writes `at.review.KIND`, the UTC time, beside each periodic review's record, and `plan-needed CHANGE` writes `at.plan-needed`, the UTC time it read the review runs, into CHANGE's run state while it holds no `phase.plan`, `phase.implement`, or `merged` record (the plan is still ahead), so a resume past the plan keeps the first time. `set` refuses an `at.*` key, which only those two commands write.
- `merged_since` clears a failing periodic security review that has a record time only for a merged change whose planner ran (`metric.planned` not `0`) and whose `at.plan-needed` is strictly later than the review's record time, its merged and `phase.plan` commits still descending from the reviewed commit; a change without the time clears nothing. A review recorded before the record times existed keeps the commit-ancestry rule.
- `passed_since` lets a failing periodic security review be superseded only by a later passing one of a scope that covers it: a whole-tree review (`review-DATE`, `sprint-N-sweep`), never a sprint's diff review (`sprint-N`); later means at a commit descending from the failing one's and, when the failing one has a record time, recorded strictly after it.
- The sprint report's Sweep line (`sweepLine`) names a partial sweep's security areas and quality areas not reviewed and says when its results were not recorded, with the hint to run `/sprint` again.
- Cases in `tools/tools_test.sh`, one per backlog heading, each failing before the fix but the missing-case one: a merge planned after the reviewed commit but before the review was recorded keeps it; a resume past the plan neither rewrites the planner's time nor clears the review; a merge planned after the review's record time clears it; a diff pass of a later sprint does not supersede a failing whole-tree review while a later whole-tree pass does; the sweep line names a partial or unrecorded sweep; and a passing periodic security review alone leaves `plan-needed` taking the head as written.
- Docs: the run state header (`at.*` keys, `plan-needed`), the comments of `merged_since`, `passed_since`, and `plan_needed`, the comment above `planReview` in `.claude/workflows/deliver-change.js`, the README pipeline step 1, and the map's `tools/run_state.sh` entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/tools_test.sh`, `.claude/workflows/sprint-planning.js`, a comment in `.claude/workflows/deliver-change.js`.
- README.md: changed, the planner's trigger names a merge planned after the review was recorded and a later whole-tree pass.
- CLAUDE.md: unchanged, its planner line (it runs only when `plan-needed` finds a decision, an unresolved blocking security finding stopping the run) still holds; the clearing rule lives in `tools/run_state.sh`, the README, and the map.
- docs/architecture.md: unchanged, it does not describe the planner trigger.
- docs/codebase-map.md: changed, the `tools/run_state.sh` entry; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect fix (T1). One reviewable pull request: the 7 review-clearing headings of the queue item; `tools/rules.sh` is not edited.

Minor assumptions:
- A whole-tree pass also supersedes a failing sprint diff review, as before, since the whole tree holds the diff; a sprint's diff pass supersedes nothing, since the next sprint's diff is another scope and no later review re-reads an earlier sprint's diff alone.
- A later pass still needs a commit after the failing review's: a second whole-tree review of the same commit that disagrees does not clear the first (the existing case kept).
- Record times are whole UTC seconds; equal times are not later (fail closed).
- The planner's time is the time `plan-needed` read the review runs before it, the one the workflow hands the planner; the `phase.plan` record itself is written later, after the implement step, so its time would count reviews recorded while the change was implemented as seen.
- The heading "No case for a passing periodic security review in plan-needed" names a missing case for behavior that already holds, so its case passes before the fix too.

## Out of scope

- The three other headings of the queue item, now in other queue items: "open-pr pins its actions by tag beside PR_TOKEN" (pr-trust-lows-c), "Lane worktree trusts a branch-controlled build/pipeline" and "Merger's lane-close and contributor's merge-main accept any change name" (lane-name-guards).
- Any change to what the planner does once it runs, or to the review records' `RESULT COMMIT SUMMARY` format.
