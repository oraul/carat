# Tasks

## 1. Class each change by its queue

- [ ] 1.1 `tools/run_state.sh`, `queue_class`: the class of a change from the queues at its merged commit's parent and at that commit, replacing `exception_item`. Tested in `tools/tools_test.sh` by "review-due leaves a T0 change out of the count", "review-due leaves out a change the exception line puts outside the 3, not one it names after run", and "review-due leaves a pool item out of the count".

## 2. Count only sprint items and their split parts

- [ ] 2.1 `tools/run_state.sh`, `sprint_state`, `sprint_row`, `groom`: `sprint_uncounted` holds every change left out, no cap; a split part of a counted change counts. Tested by "review-due counts a split part of a sprint item", "review-due leaves out every change beyond the sprint", and the groomed row cases.
- [ ] 2.2 `tools/run_state.sh`, `review_due`: the not-due line names the left-out changes by reason. Tested by "review-due names each change left out by its reason".

## 3. Documents and self-check

- [ ] 3.1 README.md, `docs/codebase-map.md`, and the header and constants of `tools/run_state.sh` describe the count.
- [ ] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
