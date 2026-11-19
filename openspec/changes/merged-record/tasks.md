# Tasks

## 1. The merge phase records its merged commit

- [x] 1.1 `tools/run_state.sh`, `phase`: the merge phase writes `merged` at its checked commit when none is recorded and refuses a recorded one naming another. Tested in `tools/tools_test.sh` by "phase merged records the merged commit with the merge phase", "phase merge at a commit records it as the merged commit", "phase merge refuses a commit other than the recorded merged", and "a refused merge phase writes neither value".

## 2. review-due names a merge it cannot count

- [x] 2.1 `tools/run_state.sh`, `merge_unrecorded`, `sprint_state`, `review_due`: a run state with a merge phase and no merged commit holds the sprint by name. Tested by "review-due names a merge phase recorded without its merged commit, a review run's left out" and "review-due leaves out a merge phase without merged of a change with a history row".

## 3. Documents and self-check

- [x] 3.1 README.md, `docs/codebase-map.md`, and the header of `tools/run_state.sh` describe the write and the held line; the `trusted` case's key order is updated.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
