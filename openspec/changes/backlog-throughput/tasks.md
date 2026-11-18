# Tasks

## 1. Groom intake and pruning

- [x] 1.1 `merged KEPT <= NEAR-SAME` in `groom` (`tools/run_state.sh`): the near-same entry's lines appended under the kept entry after a `- Merged:` line, its heading removed; refusals for an unknown heading, the same heading, a kept heading another line removes, and a security entry into a plain one; proved by "run_state: groom refuses a merge into the entry itself", "run_state: groom refuses a merge into an entry another line removes", "run_state: groom refuses a security entry merged into a plain one", "run_state: groom merges a near-same entry keeping both reasons and locations" in `tools/tools_test.sh`
- [x] 1.2 `closed COMMIT HEADING` in `groom` (`entry_added`, `touches_entry`): a commit of HEAD after the commit adding the entry, changing a file it names; proved by "run_state: groom refuses a closing commit before the entry", "run_state: groom refuses closing an entry no commit added", "run_state: groom refuses a closing commit touching no file of the entry", "run_state: groom closes an old entry with a commit after it"
- [x] 1.3 `gone HEADING` in `groom` (`entry_paths`): every path the history held absent at HEAD, at least one, never a security entry; proved by "run_state: groom refuses a gone security entry", "run_state: groom refuses a gone entry naming no path the history held", "run_state: groom refuses a gone entry whose path still stands", "run_state: groom removes an entry whose location is gone"
- [x] 1.4 `backlog-oldest FILE...` (`backlog_oldest`, `PRUNE_COUNT`): the first 50 entries' headings in order, those `groom.txt` removes left out; proved by "run_state: backlog-oldest prints the oldest entries in order, at most PRUNE_COUNT" and "run_state: backlog-oldest leaves out an entry the plan's groom.txt removes"

## 2. Docs and checks

- [x] 2.1 The `tools/run_state.sh` header, `.claude/agents/planner.md` sprint mode, `.claude/workflows/sprint-planning.js`, README.md pipeline step 11, CLAUDE.md Agents (Backlog), and the `docs/codebase-map.md` line of `tools/run_state.sh`
- [x] 2.2 The plan note's stale map line appended to `docs/findings/backlog-throughput.md`
- [x] 2.3 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
- [x] 2.4 `backlog-oldest` in the guard's read profile (`tools/agent_guard.sh`, `run_state_form`), since the planner runs under it; proved by "guard: the read profile lists the oldest backlog entries"; the planner's and sprint-planning's text proved by "agents: the sprint planner merges near-same notes and prunes the oldest entries against HEAD" and "workflow: sprint-planning hands the planner the oldest entries and the merge of near-same notes"
