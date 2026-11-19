# Tasks

## 1. Give the check clone its own toolchain

- [x] 1.1 `tools/run_state.sh`, `clone_make`, `toolchain_copy`: copy the shared toolchain into the clone, its links into the shared one pointed at the copy, and leave Spinel's checkout out. Tested in `tools/tools_test.sh` by "check copies the toolchain into its clone, its links pointed at the copy", "the clone's toolchain link names the copy", "a stage writing its clone's toolchain leaves the shared one", and "check leaves Spinel's checkout out of its clone".

## 2. Fail a check whose stage wrote outside its clone

- [x] 2.1 `tools/run_state.sh`, `escape_mark`, `escaped_paths`, `stage_record`, `check_run`, `check_stages`: the mark before the stage list, the scan and the comparisons after the stages passed. Tested by "a stage that changes the shared toolchain by an absolute path fails the check", "a stage that writes Spinel's checkout by an absolute path fails the check", "a stage that writes a tracked file of the delivery clone by an absolute path fails the check", "a stage that writes the delivery clone's run state by an absolute path fails the check", "a stage that rewrites a stage record by an absolute path fails the check", "a stage that plants a hook in the delivery clone by an absolute path fails the check", "a stage that rewrites the delivery clone's configuration by an absolute path fails the check", "a stage that writes a linked worktree's git directory fails the check", "a branch upstream written during the check leaves it passing", "a check failed by a write outside its clone ends in a verdict line", and "every check outside its clone removes the clone"; `check_wait` reads the tree with no optional lock, so a rejoining waiter leaves the index.
- [x] 2.2 Review fix: a rejoining waiter's `git status` with no optional lock is tested in a linked worktree, a tracked file's stat changed during the stage, by "a waiter rejoining a check in a linked worktree leaves its index though a tracked file's stat changed".
- [x] 2.3 Review fix: `state_view` leaves out only the figures the checker's line writes (the names of the workflow's `metricLine`), so a measurement (`metric.allocs.*`, `metric.rounds.*`, `metric.us.*`) a stage writes fails the check. Tested by "the figures a checker's line writes during a running check leave it passing" and "a stage that writes a measurement into the delivery clone's run state fails the check".
- [x] 2.4 Review fix: the scan of the common directory's `config.worktree` is tested by "a stage that writes the common directory's config.worktree by an absolute path fails the check".
- [x] 2.5 Review fix: the run-state comparison moves out of `escaped_paths` into `state_unexpected`, beside `state_view`.

## 3. Documents and self-check

- [x] 3.1 README.md and `docs/codebase-map.md` describe the clone's toolchain copy and the failed check.
- [ ] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
