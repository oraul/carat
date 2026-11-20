# Tasks

## 1. Scan the main checkout, the common info, and the global configuration

- [x] 1.1 `tools/run_state.sh`, `tree_scan` (new), `escape_mark`, `escaped_paths`: the delivery clone's scan as `tree_scan`, also over the main checkout in a lane; `escape_scan` over the common `info/` and `$HOME/.gitconfig`. Tested in `tools/tools_test.sh` by "a stage that writes the main checkout from a lane fails the check", "a stage that writes the common directory's info from a lane fails the check", and "a stage that writes HOME's git configuration fails the check".

## 2. Compare the references and the indexes

- [x] 2.1 `tools/run_state.sh`, `refs_view` (new), `escape_mark`, `escaped_paths`: the common references compared, less the remote-tracking refs and the branches of other linked worktrees. Tested by "a stage that writes a reference of the common directory from a lane fails the check".
- [x] 2.2 `tools/run_state.sh`, `index_view` (new), `escaped_paths`: the lane's git directory scanned without its index and its own entry; the staged entries of the delivery clone and, in a lane, of the main checkout compared. Tested by "a stage that stages into the lane's index fails the check", "a stage that stages into the main checkout's index from a lane fails the check", and "a lane index refresh, a remote-tracking ref, and another lane's branch written during a check leave it passing".

## 3. Documents and self-check

- [x] 3.1 README.md's checker paragraph and `docs/codebase-map.md` area 1 name what the scan covers and the new helpers.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
