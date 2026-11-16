# Proposal

## Why

Pull request 149 (`review-coverage`) made `plan-needed` name a failing periodic security review so the planner's security-first stop applies, but its quality review found a blocking bug after its one push: `merged_since` (`tools/run_state.sh:1731`) clears the review on any merge after the reviewed commit, so a delivery whose planner ran before the review clears it when it merges although no planner ever read it, and every later delivery of the queue head skips the planner again. 149 cannot take another push, so this change carries its commits unchanged on a new branch and adds the fix (T1 pipeline security, estimated small).

## What Changes

- `merged_since` counts a merged change (any history row's merged after the reviewed commit, read newest first up to the first merged at or before it, or a pending one's) as clearing a failing periodic security review only when its run state records a planner that ran after the review: its `phase.plan` commit descends from the reviewed commit and differs from it, and its `metric.planned` is not `0` (a skipped planner). Otherwise the review stands, and `plan-needed` keeps printing `needed:`, until a delivery planned after it merges or a later periodic security review passes. Later merges whose planner was skipped leave a cleared review cleared.
- `passed_since`: a failing periodic security review is superseded when a review run records a passing one (`pass`, no blocking finding) at a commit that descends from the failing review's commit and differs from it; `plan-needed` checks it after `merged_since`.
- A history row's change name is checked as a change name before its run state is read.
- Cases in `tools/tools_test.sh`: a merge planned at or before the reviewed commit leaves `plan-needed` needed, a merge whose planner was skipped leaves it needed, and a merge planned after the review clears it (the existing later-merge case, now with its plan record); that merge followed by two merges with skipped planners still clears it; a passing periodic security review of the same commit leaves the failing one standing and one of a later commit supersedes it.
- Docs: the `plan-needed` line of the `tools/run_state.sh` header, the comment above `planReview` in `.claude/workflows/deliver-change.js`, the README pipeline step 1, and the map's `tools/run_state.sh` entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/tools_test.sh`, a comment in `.claude/workflows/deliver-change.js`.
- README.md: changed, the planner's trigger names a merge planned after the review.
- CLAUDE.md: unchanged, its planner line (it runs only when `plan-needed` finds a decision, an unresolved blocking security finding stopping the run) still holds; the clearing rule lives in `tools/run_state.sh`, the README, and the map.
- docs/architecture.md: unchanged, it does not describe the planner trigger.
- docs/codebase-map.md: changed, the `tools/run_state.sh` entry; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline security fix (T1). One reviewable pull request, not split. It supersedes pull request 149, which the user closes after this one merges.

Minor assumptions: a plan recorded at the reviewed commit itself does not clear the review, since its time against the review's cannot be told from the commit (fail closed: the next delivery's planner, at a later main commit, clears it); a run state without `metric.planned` counts as planned, as runs before the figure existed recorded none and a skipped planner always records `0`; a history row whose change has no run state, or no `phase.plan`, clears nothing.

## Out of scope

- Recording the review's or the planner's time in the run state, and any change to what the planner does once it runs.
- The advisories 149 already recorded, and any other change to the review-coverage commits carried from 149.
