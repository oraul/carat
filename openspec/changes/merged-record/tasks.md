# Tasks

## 1. The merge phase records its merged commit

- [x] 1.1 `tools/run_state.sh`, `phase`: the merge phase writes `merged` at its checked commit when none is recorded and refuses a recorded one naming another. Tested in `tools/tools_test.sh` by "phase merged records the merged commit with the merge phase", "phase merge at a commit records it as the merged commit", "phase merge refuses a commit other than the recorded merged", and "a refused merge phase writes neither value".

## 2. review-due names a merge it cannot count

- [x] 2.1 `tools/run_state.sh`, `merge_unrecorded`, `sprint_state`, `review_due`: a run state with a merge phase and no merged commit holds the sprint by name. Tested by "review-due names a merge phase recorded without its merged commit, a review run's left out" and "review-due leaves out a merge phase without merged of a change with a history row".

## 3. Documents and self-check

- [x] 3.1 README.md, `docs/codebase-map.md`, and the header of `tools/run_state.sh` describe the write and the held line; the `trusted` case's key order is updated.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.

## 4. Review advisories fixed in place

- [x] 4.1 `tools/run_state.sh`: `review_due` collects `merge_unrecorded` itself; `sprint_state`, which `groom` and `sprint-row` also call, no longer computes `sprint_uncounted`.
- [x] 4.2 `tools/run_state.sh`, `phase`: the recorded-merged refusal sits in the `merge:*` arm beside `merged_at`, since `squash_of_change` already checks it for the word `merged`; after the case only the write of an empty `merged` remains.
- [x] 4.3 `tools/tools_test.sh`: "review-due names no merge phase that is not a commit hash" and "review-due names the waiting plan before a merge phase without its merged commit".
- [x] 4.4 `tools/tools_test.sh`: the history-row case writes its run state before the row, since `init` refuses a name with a history row, so the case no longer passes with no run state to leave out.
