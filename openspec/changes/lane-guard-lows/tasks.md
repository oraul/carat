# Tasks

## 1. Lane and merge guards

- [x] 1.1 Refuse tracked or linked lane paths in `lane_open` (`tools/run_state.sh`); proved by the lane-open cases in `tools/tools_test.sh`
- [x] 1.2 Run `merge_main`'s git through `pinned_git` (`tools/run_state.sh`); proved by the merge-main hook case
- [x] 1.3 Refuse `note.*` in `set` (`tools/run_state.sh`); proved by the set case

## 2. The pull request picked

- [x] 2.1 Check the head repository and branch in `open_pr.sh wait` (`tools/open_pr.sh`); proved by the wait cases

## 3. Tests and docs

- [x] 3.1 Add the cases to `tools/tools_test.sh`, each failing before the change, and write forged notes by the file
- [x] 3.2 Update the headers of `tools/run_state.sh` and `tools/open_pr.sh`
