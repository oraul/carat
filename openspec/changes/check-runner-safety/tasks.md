# Tasks

## 1. Give the check clone its own toolchain

- [ ] 1.1 `tools/run_state.sh`, `clone_make`, `toolchain_copy`: copy the shared toolchain into the clone, its links into the shared one pointed at the copy, and leave Spinel's checkout out. Tested in `tools/tools_test.sh` by "check copies the toolchain into its clone, its links pointed at the copy", "a stage writing its clone's toolchain leaves the shared one", and "check leaves Spinel's checkout out of its clone".

## 2. Fail a check whose stage wrote outside its clone

- [ ] 2.1 `tools/run_state.sh`, `escape_mark`, `escaped_paths`, `stage_record`, `check_run`, `check_stages`: the mark before the stage list, the scan and the comparisons after the stages passed. Tested by "a stage that changes the shared toolchain by an absolute path fails the check", "a stage that writes Spinel's checkout by an absolute path fails the check", "a stage that writes a tracked file of the delivery clone by an absolute path fails the check", "a stage that writes the delivery clone's run state by an absolute path fails the check", "a stage that rewrites a stage record by an absolute path fails the check", "a stage that plants a hook in the delivery clone by an absolute path fails the check", "a stage that rewrites the delivery clone's configuration by an absolute path fails the check", "a stage that writes a linked worktree's git directory fails the check", and "a branch upstream written during the check leaves it passing".

## 3. Documents and self-check

- [ ] 3.1 README.md and `docs/codebase-map.md` describe the clone's toolchain copy and the failed check.
- [ ] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
