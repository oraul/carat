# Tasks

## 1. Stale proof

- [x] 1.1 `stale HEADING` in `groom` (`tools/run_state.sh`, `stale_mark`, `named_since`), refused for a security entry; proved by "run_state: groom refuses a stale security entry", "run_state: groom refuses a stale line before three sprint rows", "run_state: groom refuses a stale entry added at or after the third-last sprint row", "run_state: groom refuses a stale entry named again since", and "run_state: groom removes a stale entry and a folded one" in `tools/tools_test.sh`

## 2. Whole-backlog scan

- [x] 2.1 `PRUNE_ALL_SPRINT` in `backlog_oldest` (`tools/run_state.sh`), `PRUNE_COUNT` a constant; proved by "run_state: backlog-oldest lists every entry at the close of PRUNE_ALL_SPRINT" and "run_state: backlog-oldest keeps 50 in another sprint"

## 3. Docs and checks

- [x] 3.1 The `tools/run_state.sh` header, `.claude/agents/planner.md` step 1 (its test in `tools/tools_test.sh`), CLAUDE.md's Backlog line, README.md pipeline step 11, and `docs/codebase-map.md` (`tools/run_state.sh`)
- [x] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass

## 4. Review fixes

- [x] 4.1 Refuse stale while a lane queue or the plan's holds the title; proved by "run_state: groom refuses a stale entry a lane queue still names, though queued in the commit adding it"
- [x] 4.2 `stale_mark` finds the row's commit by its sprint name; proved by "run_state: groom refuses a stale entry added after the third-last sprint row, the row corrected since"
- [x] 4.3 One way to ask for the whole scan: `PRUNE_COUNT` no longer read from the environment, its `all` and refusal cases removed; removing `PRUNE_ALL_SPRINT` after the sprint-24 close recorded in `docs/findings/groom-stale-prune.md`
- [x] 4.4 An exported `PRUNE_COUNT` no longer reaches `backlog-oldest`, so the tools-test cases hold in any shell (by 4.3)
- [x] 4.5 `named_history` walks the backlog, findings, and queue history once per groom run; `named_since` takes only the commits of its range from it
- [x] 4.6 `.claude/agents/planner.md` keeps "Each decision is one line." and "(which `groom` folds in)", its new words shortened
- [x] 4.7 Cases for a later `- Merged:` line blocking stale and a queue item moved unchanged not blocking it: "run_state: groom refuses a stale entry a later - Merged: line names" and "run_state: groom removes a stale entry, a folded one, and one whose queue item moved unchanged"
- [x] 4.8 A stale heading with no title refused; proved by "run_state: groom refuses a stale heading with no title"
