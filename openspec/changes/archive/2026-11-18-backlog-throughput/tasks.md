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

## 3. Review fixes

- [x] 3.1 `entry_added` matches the whole heading line (`git log --pickaxe-regex -S` with the heading escaped and anchored), so an older heading it only prefixes is not the commit adding the entry; proved by "run_state: groom refuses a closing commit before the entry, an older heading it only prefixes not taken for it"
- [x] 3.2 `closed` refuses a security entry (security review, Low (4)): a later commit touching its file proves no fix, so it leaves only by `listed` or `fixed`; proved by "run_state: groom refuses closing a security entry, though a later commit touches its file"; README.md, `.claude/agents/planner.md`, the proposal, and the design say so, and CLAUDE.md's "a security entry only listed or fixed" holds again
- [x] 3.3 `ENTRY_AWK` holds the groomed set (`load_groomed`) and the entry test (`backlog_entry_head`) `backlog_pick` and `backlog_oldest` share; `entry_naming` prints the naming text `touches_entry` and `entry_paths` read; no behavior moves, the backlog-pick, backlog-oldest, fixed, and gone cases still pass
- [x] 3.4 A merged line whose heading another line already removes is refused; proved by "run_state: groom refuses merging one heading twice"
- [x] 3.5 The allowed security path is proved: "run_state: groom merges a security entry into another security entry"
- [x] 3.6 The `docs/codebase-map.md` line of `tools/run_state.sh` says `groom` refuses a closed, duplicate, or gone line for a security entry and removes neither a merged nor its kept heading by another line, naming `entry_naming` beside `entry_paths` and `ENTRY_AWK` for `backlog-oldest` (quality advisory, docs currency); no behavior moves
