
### PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439

- Location: tools/run_state.sh:439 (`PRUNE_ALL_SPRINT=sprint-24`, read by `backlog_oldest`), its case "run_state: backlog-oldest lists every entry at the close of PRUNE_ALL_SPRINT" in tools/tools_test.sh, and its mentions in the run_state.sh header and docs/codebase-map.md.
- Why: the constant makes the sprint-24 close's scan whole, the user's one whole-backlog scan of 2026-11-20; once sprint-24 closes it never matches again, dead code beside `PRUNE_COUNT`.
- Fix: after the sprint-24 close, remove `PRUNE_ALL_SPRINT`, its line in `backlog_oldest`, `sprint_next` when nothing else reads it, its test cases, and its header and code-map words.
