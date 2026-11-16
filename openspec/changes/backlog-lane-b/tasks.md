# Tasks

## 1. The pick

- [x] 1.1 `tools/run_state.sh` `backlog-pick [FILE...]` (`backlog_pick`, `PICK_BATCHES`, `PICK_MIN`, `PICK_MAX`), its header entry, and its dispatch; proved in `tools/tools_test.sh` by "run_state: backlog-pick puts a security entry first whatever its age", "run_state: backlog-pick batches one area, oldest first, at most 10", "run_state: backlog-pick passes over an area of fewer than 5", "run_state: backlog-pick skips an entry a queued item names", "run_state: backlog-pick reports an unmapped entry", "run_state: backlog-pick gives an area under 5 its security entries alone", "run_state: backlog-pick reads the backlog and findings files by default", "run_state: backlog-pick prints no batch when none qualifies", and "run_state: backlog-pick refuses a missing file"

## 2. The planner

- [ ] 2.1 `.claude/agents/planner.md` sprint mode: the backlog items from the pick, the one-time triage, the calibration rule, within its budget; proved by "agents: the sprint planner runs the pick, the triage, and the calibration"
- [ ] 2.2 `.claude/workflows/sprint-planning.js` Plan step and sprint prompt name the pick and the triage; proved by "sprint: the plan step names the pick and the triage"

## 3. Docs

- [ ] 3.1 `docs/codebase-map.md` area 1 names `backlog-pick`; README.md's sprint planning step names the pick, the triage, and the calibration; `make docs-lint` and `make gates` pass
