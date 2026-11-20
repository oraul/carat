# Tasks

## 1. Stale proof

- [x] 1.1 `stale HEADING` in `groom` (`tools/run_state.sh`, `stale_mark`, `named_since`), refused for a security entry; proved by "run_state: groom refuses a stale security entry", "run_state: groom refuses a stale line before three sprint rows", "run_state: groom refuses a stale entry added at or after the third-last sprint row", "run_state: groom refuses a stale entry named again since", and "run_state: groom removes a stale entry and a folded one" in `tools/tools_test.sh`

## 2. Whole-backlog scan

- [x] 2.1 `PRUNE_COUNT` from the environment, `all` for every entry, and `PRUNE_ALL_SPRINT` in `backlog_oldest` (`tools/run_state.sh`); proved by "run_state: backlog-oldest lists every entry with PRUNE_COUNT=all", "run_state: backlog-oldest lists every entry at the close of PRUNE_ALL_SPRINT", "run_state: backlog-oldest keeps 50 in another sprint", and "run_state: backlog-oldest refuses a PRUNE_COUNT that is no number"

## 3. Docs and checks

- [x] 3.1 The `tools/run_state.sh` header, `.claude/agents/planner.md` step 1 (its test in `tools/tools_test.sh`), CLAUDE.md's Backlog line, README.md pipeline step 11, and `docs/codebase-map.md` (`tools/run_state.sh`)
- [ ] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
