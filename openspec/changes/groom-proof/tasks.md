# Tasks

## 1. Groom proofs

- [x] 1.1 `listed` in `groom` (`tools/run_state.sh`, `item_lists`) requires a change of the sprint whose queue item holds the heading; proved by "run_state: groom refuses a listed change outside the sprint", "run_state: groom refuses a listed change whose item lacks the heading", and "run_state: groom removes a merged item's listed headings and no others" in `tools/tools_test.sh`
- [x] 1.2 `fixed` in `groom` (`tools/run_state.sh`, `touches_entry`) requires a commit of the sprint's range changing a file the entry names; proved by "run_state: groom refuses a fixing commit at or before the sprint's base", "run_state: groom refuses a fixing commit touching no file of the entry", "run_state: groom removes a security entry with its fixing commit", and "run_state: groom removes a group of findings with a commit touching a file it names"
- [x] 1.3 The duplicate guard reads a security severity marker; proved by "run_state: groom keeps a disputed security entry", "run_state: groom keeps a security finding inside a group", and "run_state: groom removes a duplicate whose text only mentions security"

## 2. Docs and checks

- [x] 2.1 The `groom` lines of the `tools/run_state.sh` header, README.md pipeline step 11, `docs/codebase-map.md` (`tools/run_state.sh`), and `.claude/agents/planner.md` step 1
- [ ] 2.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
