# Tasks

## 1. Plain git in merge_main

- [x] 1.1 Run `merge_main`'s merge, queue checkout, add, commit, and abort with plain git, keep its fetch pinned, reword the conflict message and the `merge-main` header (`tools/run_state.sh`); prove it in `tools/tools_test.sh` (case: merge_main runs plain git past its fetch)
- [x] 1.2 Remove the two hook cases of #328 from `tools/tools_test.sh`

## 2. Conflicts go to the contributor

- [x] 2.1 Have the main-moved start's task resolve every conflict and commit the merge without stopping (`.claude/workflows/deliver-change.js`); prove it in `tools/tools_test.sh` (case: a same-logic conflict goes to the contributor, not a stop)
- [x] 2.2 Update the conflict rules in `docs/contributor-notes.md` and the two sentences in `README.md`

## 3. Findings

- [x] 3.1 Append the reopened hook finding to `docs/findings/merge-git-unpin.md`
