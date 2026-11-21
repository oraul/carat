# Tasks

## 1. Evidence only

- [x] 1.1 `groom` refuses `stale` and `closed` lines (`tools/run_state.sh`), and `entry_added`, `stale_mark`, `named_history`, `named_since`, `sprint_next`, and `PRUNE_ALL_SPRINT` are removed; proved by "run_state: groom refuses a stale line, which removes an entry only for its age" and "run_state: groom refuses a closed line, which removes an entry a later commit only touched" in `tools/tools_test.sh`
- [x] 1.2 `gone HEADING -- REASON` required, `load_groomed` reading the heading before the reason; proved by "run_state: groom refuses a gone line with no reason", "run_state: groom refuses a gone line with a blank reason", "run_state: groom refuses a gone line whose reason is not set off by spaces", "run_state: groom removes an entry whose location is gone, with its reason", and "run_state: backlog-oldest leaves out an entry the plan's groom.txt removes, a gone line's reason cut"
- [x] 1.3 listed, fixed, merged, and duplicate still accepted; proved by "run_state: groom applies the sprint plan" and "run_state: groom removes an old entry fixed by a commit of the sprint"

## 2. Docs and checks

- [x] 2.1 The `tools/run_state.sh` header and comments, `.claude/agents/planner.md` step 1 (its test in `tools/tools_test.sh`), CLAUDE.md's Backlog line, README.md pipeline step 11, and `docs/codebase-map.md`
- [x] 2.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
