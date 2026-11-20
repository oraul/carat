### plan-needed names only the first failing review while merged_since clears every one before the planner's time
- Location: tools/run_state.sh:3312 (plan_needed), with merged_since; quality advisory, pre-existing gap in the rule this change tightens
- Why: plan_needed hands the planner only the first failing review, yet merged_since clears every failing review recorded before that planner's at.plan-needed, so a second failing review is cleared without the planner having been given it
- Fix: name every failing review run in the needed line (and in planReview of .claude/workflows/deliver-change.js), or clear only the review that was named
