# Tasks

## 1. The pick

- [x] 1.1 `tools/run_state.sh` `backlog-pick FILE...` (`backlog_pick`, `PICK_BATCHES`, `PICK_MIN`, `PICK_MAX`), its header entry, and its dispatch; proved in `tools/tools_test.sh` by "run_state: backlog-pick puts a security entry first whatever its age", "run_state: backlog-pick batches one area, oldest first, at most 10", "run_state: backlog-pick passes over an area of fewer than 5", "run_state: backlog-pick skips an entry a queued item names", "run_state: backlog-pick reports an unmapped entry", "run_state: backlog-pick skips an entry the plan's groom.txt removes", "run_state: backlog-pick gives an area under 5 its security entries alone", "run_state: backlog-pick with no file prints its usage and reads no backlog", "run_state: backlog-pick prints no batch when none qualifies", and "run_state: backlog-pick refuses a missing file"

## 2. The planner

- [x] 2.1 `.claude/agents/planner.md` sprint mode: the backlog items from the pick, the one-time triage, the calibration rule, within its budget; proved by "agents: the sprint planner runs the pick over the backlog and findings files, the triage, and the calibration"
- [x] 2.2 `.claude/workflows/sprint-planning.js` Plan step and sprint prompt name the pick and the triage; proved by "sprint: the plan step names the pick over the backlog and findings files, and the triage"

## 3. Docs

- [x] 3.1 `docs/codebase-map.md` area 1 names `backlog-pick`; README.md's sprint planning step names the pick, the triage, and the calibration; `make docs-lint` and `make gates` pass

## 4. Review fixes

- [x] 4.1 The pick reads `##` and deeper headings, `- Where:` and `- Why it matters:` lines, and a heading's path:line without a Location, and maps every backticked path of an area's lines; proved by "run_state: backlog-pick reads ## entries with Where and Why it matters lines", "run_state: backlog-pick places an entry by its heading's path without a Location", "run_state: backlog-pick maps a path on a Tests: line of an area", and "run_state: backlog-pick maps every path of a bullet and skips a section heading"
- [x] 4.2 The pick places a Location by the first path of its line the map holds, backticked first, or a directory holding a mapped path, a line opening with a symbol, a constant, or prose included; proved by "run_state: backlog-pick places a Location by its first mapped path or directory, a symbol or prose first"

## 5. backlog-lane-c

- [x] 5.1 Carry backlog-lane-b's commits and rename the change to `backlog-lane-c`, in `docs/queue-backlog.md`'s exception and parallel-lanes lines too
- [x] 5.2 A bare backticked word of a Location places it only when the map names it and the tree holds it as a file or directory (`named_file`); proved by "run_state: backlog-pick places a Location by its mapped path, never by an identifier before it"
- [x] 5.3 The pick requires its files, printing its usage and exiting 2 with none; the planner's sprint mode and sprint-planning pass `docs/backlog.md` and `docs/findings/*.md`, and the header, README.md, and the code map say so; proved by "run_state: backlog-pick with no file prints its usage and reads no backlog" and the two renamed planner and sprint cases
- [x] 5.4 The groom header column and the pick's header wrap aligned; the repeated "for the contributor" dropped from `.claude/agents/planner.md`
