### The code map says the backlog lane's sprint holds 0 to 2 items

- Location: docs/codebase-map.md:55, tools/docs_lint.sh:23 (its header, check_lane)
- Why: sprint-size-six made a sprint 3 features and 3 backlog items, so the map's "0 to 2" for the backlog lane's `## Sprint` is stale and misleads a reader of the lane rules (the planner's note on backlog-throughput).
- Fix: say 0 to 3 in the map line and confirm `check_lane` in tools/docs_lint.sh enforces the same bound, with a docs-lint case.

### The planner's guard refuses backlog-pick, which its sprint mode runs

- Location: tools/agent_guard.sh:613 (run_state_form, the read profile)
- Why: the planner's sprint mode (.claude/agents/planner.md step 2, sprint-planning.js line 222) runs `sh tools/run_state.sh backlog-pick docs/backlog.md docs/findings/*.md`, but the read profile lists only backlog-dups among the backlog commands, so the guard refuses it ("refused for the read profile: tools/run_state.sh backlog-pick") and the planner must pick the batches by hand; backlog-throughput added backlog-oldest to the profile but left backlog-pick out of scope.
- Fix: add `read:backlog-pick` to the read profile and its header comment, with a guard case beside "guard: the read profile lists backlog duplicates" in tools/tools_test.sh.
