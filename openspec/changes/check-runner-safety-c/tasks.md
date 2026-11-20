# Tasks

## 1. Scan the main checkout, the common info, and the global configuration

- [x] 1.1 `tools/run_state.sh`, `tree_scan` (new), `escape_mark`, `escaped_paths`: the delivery clone's scan as `tree_scan`; `escape_scan` over the common `info/` and `$HOME/.gitconfig`. Tested in `tools/tools_test.sh` by "a stage that writes the common directory's info from a lane fails the check" and "a stage that writes HOME's git configuration fails the check".
- [x] 1.2 `tools/run_state.sh`, `main_scan`, `main_view`, `main_moved` (new): from a lane, the main checkout's untracked files, its state against its HEAD, and its HEAD. Tested by "a stage that writes a tracked file of the main checkout from a lane fails the check", "a stage that writes an untracked file of the main checkout from a lane fails the check", "a stage that stages into the main checkout's index from a lane fails the check", and "a stage that moves the main checkout from a lane fails the check".

## 2. Compare the references and the lane's index

- [x] 2.1 `tools/run_state.sh`, `refs_view`, `lane_branches` (new): the common references compared, less the remote-tracking refs, the lanes' branches at the mark or the scan, and the main checkout's branch. Tested by "a stage that writes a reference of the common directory from a lane fails the check".
- [x] 2.2 `tools/run_state.sh`, `index_view` (new), `escaped_paths`: the lane's git directory scanned without its index and its own entry; the delivery clone's staged entries compared. Tested by "a stage that stages into the lane's index fails the check".
- [x] 2.3 Concurrent work leaves a lane check passing: a lane index refresh, another lane's commit, a lane's worktree removed with its branch kept, and the main checkout fast-forwarded to its remote-tracking ref. Tested by "a lane index refresh, a lane's commit, a merger's close and fast-forward during a check leave it passing" and "the fast-forward during the check moved the main checkout".

## 3. Documents and self-check

- [x] 3.1 README.md's checker paragraph and `docs/codebase-map.md` area 1 name what the scan covers and the new helpers.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
