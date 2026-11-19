# Tasks

## 1. Class each change by its queue

- [x] 1.1 `tools/run_state.sh`, `queue_class`: the class of a change from the queues at its merged commit's parent and at that commit, replacing `exception_item`. Tested in `tools/tools_test.sh` by "review-due leaves a T0 change out of the count", "review-due leaves out a change the exception line puts outside the 3, not one it names after run", and "review-due leaves a pool item out of the count".

## 2. Count only sprint items and their split parts

- [x] 2.1 `tools/run_state.sh`, `sprint_state`, `sprint_row`, `groom`: `sprint_uncounted` holds every change left out, no cap; a split part of a counted change counts. Tested by "review-due counts a split part of a sprint item", "review-due leaves out every change beyond the sprint", and the groomed row cases.
- [x] 2.2 `tools/run_state.sh`, `review_due`: the not-due line names the left-out changes by reason. Tested by "review-due names each change left out by its reason".

## 3. Documents and self-check

- [x] 3.1 README.md, `docs/codebase-map.md`, and the header and constants of `tools/run_state.sh` describe the count.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.

## 4. Review fixes

- [x] 4.1 `tools/tools_test.sh`: the sprintcount fixture holds a pool item `u1-c` beside a counted sprint item `u1-b`, `u1` unmerged, so `split_part`'s sibling branch decides it. Tested by "review-due counts a pool item split from a counted sibling part".
- [x] 4.2 `tools/run_state.sh`, `queue_records`: one reader of the queue line form for `queue_class` and `queue_items`; only a `#` or `##` heading sets the sprint, so an item under a `###` sub-heading of the sprint counts. Tested by "review-due counts an item under a sub-heading of its sprint".
- [x] 4.3 `tools/run_state.sh`: the usage header lists `review-due` once; `tools/tools_test.sh`: the comment before the y2 case names `queue_class`.
- [x] 4.4 `tools/tools_test.sh`: the split-part, sub-heading, and sibling-part cases each assert their own name is absent from every not-counted list (`counted`), the count and the pool list kept in one case, so no label repeats another's check.

## 5. Closing advisories

- [x] 5.1 `tools/tools_test.sh`, `counted`: a name also has to appear in review-due's merged list, the part before the first `)`, so a change review-due never saw prints `unseen NAME` and fails its case.
