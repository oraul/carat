
### PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439

- Location: tools/run_state.sh:439 (`PRUNE_ALL_SPRINT=sprint-24`, read by `backlog_oldest`), its case "run_state: backlog-oldest lists every entry at the close of PRUNE_ALL_SPRINT" in tools/tools_test.sh, and its mentions in the run_state.sh header and docs/codebase-map.md.
- Why: the constant makes the sprint-24 close's scan whole, the user's one whole-backlog scan of 2026-11-20; once sprint-24 closes it never matches again, dead code beside `PRUNE_COUNT`.
- Fix: after the sprint-24 close, remove `PRUNE_ALL_SPRINT`, its line in `backlog_oldest`, `sprint_next` when nothing else reads it, its test cases, and its header and code-map words.

### A lane's check fails on another lane's write into the main checkout's build/metrics
- Location: tools/run_state.sh escaped_paths and main_scan (about :1158), clone_drop (about :1282, the copy to the relative metrics_out), bench (build/metrics/last.tsv)
- Why: groom-stale-prune's check at b46fe59 passed every stage, then failed as "stage none" because /home/user/carat/build/metrics/current.tsv changed at 19:13:45, the moment the feature lane's check runner (status-winbar-tabs-b) dropped its clone and wrote its carry, and last.tsv changed at 19:13:53; no stage of this lane wrote there (its own measurement went to the worktree's build/metrics at 19:20:15). A runner or bench whose working directory is the main checkout copies its figures into the main checkout's build/, and main_scan counts any such write against whichever lane's check is running, so two lanes at once can fail each other's check with a false escape.
- Fix: make clone_drop and bench write metrics_out under the runner's own top (an absolute path from check_run's pwd, refused when it is the main checkout while the clone is a lane), and leave the main checkout's build/metrics out of main_scan or attribute it by the writing runner's pid file; add a tools-test case running two lanes' runners where one writes the main checkout's build/metrics and the other's check still passes.

### The second groom-stale-prune finding lacks a blank line and names an absolute path

- Location: docs/findings/groom-stale-prune.md:8, the second entry (reported by two quality review passes, unchanged between them).
- Why: it has no blank line after its heading, unlike the first entry and the other findings files, and it names the absolute checkout path of build/metrics/current.tsv, which ties the note to one machine.
- Fix: in the grooming that folds this file in, add the blank line after the heading and name the path relative to the main checkout (build/metrics/current.tsv).
