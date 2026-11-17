### The goals rubric still splits only a brief of more than about four fixes
- Location: docs/goals.md:24
- Why: the planner decides by the goals rubric (planner.md step 2), which still splits only a brief of more than about four separate fixes, contradicting planner.md step 3's split at three or more independently testable parts or map areas, so the planner can read two thresholds.
- Fix: rewrite goals.md line 24 to the three-part or three-area threshold when the planner is next asked for goals, or point it at planner.md step 3.

### planner.md says the contributor appends the plan's backlog file
- Location: .claude/agents/planner.md:25
- Why: step 5 says the contributor appends build/plan backlog.md to its findings file, but plan-apply does it (tools/run_state.sh plan_apply) and the CLAUDE.md Backlog bullet says so, so the planner's rules drift from the script.
- Fix: write "which plan-apply appends to the change's findings file", within the 8,192-byte budget.

### The CLAUDE.md planner bullet names only build/plan/CHANGE/
- Location: CLAUDE.md:205
- Why: the planner bullet says the planner writes into build/plan/CHANGE/, but its sprint mode and /plan write to build/plan/ (planner.md:25, sprint-planning.js:9), so the bullet misplaces the sprint plan.
- Fix: "into build/plan/ (CHANGE/ in a delivery)" when the bytes allow, with the user's approval, since the wording was approved verbatim.
